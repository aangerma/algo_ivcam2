function [outregs,minerr,eFit,dnew]=calibDFZ(d,regs,verbose)

if(~exist('verbose','var'))
    verbose=true;
end

%some filtering - remove NANS
im = double(d.i);
im(im==0)=nan;
N=3;
imv = im(Utils.indx2col(size(im),[N N]));
bd = vec(isnan(im));
im(bd)=nanmedian_(imv(:,bd));

%calc RTD 
[~,r] = Pipe.z16toVerts(d.z,regs);
[~,~,~,~,~,~,sing]=Pipe.DEST.getTrigo(size(r),regs);
C=r*regs.DEST.baseline.*sing- regs.DEST.baseline2;
rtd=r+sqrt(r.^2-C);
rtd=rtd+regs.DEST.txFRQpd(1);

%calc angles per pixel
[yg,xg]=ndgrid(0:size(rtd,1)-1,0:size(rtd,2)-1);
[angx,angy]=Pipe.CBUF.FRMW.xy2ang(xg,yg,regs);

%xy2ang verification
% [~,~,xF,yF]=Pipe.DIGG.ang2xy(angx,angy,regs,Logger(),[]);
% assert(max(vec(abs(xF-xg)))<0.1,'xy2ang invertion error')
% assert(max(vec(abs(yF-yg)))<0.1,'xy2ang invertion error')

%find CB points
[p,bsz] = detectCheckerboardPoints(normByMax(im)); % p - 3 checkerboard points. bsz - checkerboard dimensions.
it = @(k) interp2(xg,yg,k,reshape(p(:,1)-1,bsz-1),reshape(p(:,2)-1,bsz-1)); % Used to get depth and ir values at checkerboard locations.

%rtd,ohi,theta
rpt=cat(3,it(rtd),it(angx),it(angy)); % Convert coordinate system to angles instead of xy. Makes it easier to apply zenith optimization.

% Define optimization settings
%%
opt.maxIter=10000;
opt.OutputFcn=[];
opt.TolFun = 0.0025;
opt.TolX = inf;
opt.Display='none';


angXShift = 0;
x0 = double([regs.FRMW.xfov regs.FRMW.yfov regs.DEST.txFRQpd(1) regs.FRMW.laserangleH regs.FRMW.laserangleV angXShift]);
% x0 = double([68.186935 52.944909 5153.491386 0.299999 -0.283499 angXShift])
xL = [40 40 4000   -.3 -.3 0];
xH = [90 90 6000    .3  .3 0];
load
[e,eFit]=errFunc(rpt,regs,x0,verbose);

[xbest,minerr]=fminsearchbnd(@(x) errFunc(rpt,regs,x,0),x0,xL,xH,opt);
[xbest,minerr]=fminsearchbnd(@(x) errFunc(rpt,regs,x,0),xbest,xL,xH,opt);
[xbest,minerr]=fminsearchbnd(@(x) errFunc(rpt,regs,x,0),xbest,xL,xH,opt);
% [xbest,minerr]=fminsearch(@(x) errFunc(rpt,regs,x,0),x0,opt);
outregs = x2regs(xbest,regs);
rpt_new = cat(3,it(rtd),it(angx+xbest(6)),it(angy));
[e,efit]=errFunc(rpt_new,outregs,xbest,verbose);
%% 
% 
% for sh = -1000:200:1000
%     regs.FRMW.marginL = 200;
%     regs.FRMW.marginR = -200;
%     
%     outregs = x2regs(xbest,regs);
%     figure
%     [e,v,xF,yF]=errFunc(cat(3,it(rtd),it(angx),it(angy)),outregs,xbest,verbose);
%     view([0,90])
%     
% end


[zNewVals,xF,yF]=rpt2z(cat(3,rtd,angx+xbest(6),angy),outregs);

ok=~isnan(xF) & ~isnan(yF)  & d.i>1;
dnew.z = griddata(double(xF(ok)),double(yF(ok)),double(zNewVals(ok)),xg,yg);
dnew.i = griddata(double(xF(ok)),double(yF(ok)),double(d.i(ok)),xg,yg);
dnew.c = griddata(double(xF(ok)),double(yF(ok)),double(d.c(ok)),xg,yg);

end


function [z,xF,yF] = rpt2z(rpt,rtlRegs)

[~,~,xF,yF]=Pipe.DIGG.ang2xy(rpt(:,:,2),rpt(:,:,3),rtlRegs,Logger(),[]);
rtd_=rpt(:,:,1)-rtlRegs.DEST.txFRQpd(1);
[sinx,cosx,~,cosy,sinw,cosw,sing]=Pipe.DEST.getTrigo(round(xF),round(yF),rtlRegs);
r = (0.5*(rtd_.^2 - rtlRegs.DEST.baseline2))./(rtd_ - rtlRegs.DEST.baseline.*sing);
z = r.*cosw.*cosx;
z = z * rtlRegs.GNRL.zNorm;
end
function [e,eFit]=errFunc(rpt,rtlRegs,X,verbose)
%build registers array

rtlRegs = x2regs(X,rtlRegs);

[~,~,xF,yF]=Pipe.DIGG.ang2xy(rpt(:,:,2)+X(6),rpt(:,:,3),rtlRegs,Logger(),[]);


rtd_=rpt(:,:,1)-rtlRegs.DEST.txFRQpd(1);


[sinx,cosx,~,cosy,sinw,cosw,sing]=Pipe.DEST.getTrigo(round(xF),round(yF),rtlRegs);

r= (0.5*(rtd_.^2 - rtlRegs.DEST.baseline2))./(rtd_ - rtlRegs.DEST.baseline.*sing);

z = r.*cosw.*cosx;
x = r.*cosy.*sinx;
y = r.*sinw;
v=cat(3,x,y,z);


[e,eFit]=Calibration.aux.evalGeometricDistortion(v,verbose);
if(verbose)
    fprintf('%f ',[X]);
    fprintf('eAlex: %f ',[e]);
    fprintf('eFit: %f ',[eFit]);
    
    fprintf('\n');
end
end
function rtlRegs = x2regs(x,rtlRegs)



iterRegs.FRMW.xfov=single(x(1));
iterRegs.FRMW.yfov=single(x(2));
iterRegs.FRMW.gaurdBandH=single(0);
iterRegs.FRMW.gaurdBandV=single(0);
iterRegs.FRMW.xres=rtlRegs.GNRL.imgHsize;
iterRegs.FRMW.yres=rtlRegs.GNRL.imgVsize;
iterRegs.FRMW.marginL=int16(0);
iterRegs.FRMW.marginT=int16(0);

iterRegs.FRMW.xoffset=single(0);
iterRegs.FRMW.yoffset=single(0);
iterRegs.FRMW.undistXfovFactor=single(1);
iterRegs.FRMW.undistYfovFactor=single(1);
iterRegs.DEST.txFRQpd=single([1 1 1]*x(3));
iterRegs.DIGG.undistBypass = false;
iterRegs.GNRL.rangeFinder=false;


iterRegs.FRMW.laserangleH=single(x(4));
iterRegs.FRMW.laserangleV=single(x(5));

rtlRegs =Firmware.mergeRegs( rtlRegs ,iterRegs);

trigoRegs = Pipe.DEST.FRMW.trigoCalcs(rtlRegs);
rtlRegs =Firmware.mergeRegs( rtlRegs ,trigoRegs);

diggRegs = Pipe.DIGG.FRMW.getAng2xyCoeffs(rtlRegs);
rtlRegs=Firmware.mergeRegs(rtlRegs,diggRegs);
end
