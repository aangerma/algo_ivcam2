function [outregs,minerr,dnew]=calibDFZ(d,regs,verbose)

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
[~,~,xF,yF]=Pipe.DIGG.ang2xy(angx,angy,regs,Logger(),[]);
assert(max(vec(abs(xF-xg)))<0.1,'xy2ang invertion error')
assert(max(vec(abs(yF-yg)))<0.1,'xy2ang invertion error')

%find CB points
[p,bsz] = detectCheckerboardPoints(normByMax(im)); % p - 3 checkerboard points. bsz - checkerboard dimensions.
it = @(k) interp2(xg,yg,k,reshape(p(:,1)-1,bsz-1),reshape(p(:,2)-1,bsz-1)); % Used to get depth and ir values at checkerboard locations.

%rtd,ohi,theta
rpt=cat(3,it(rtd),it(angx),it(angy)); % Convert coordinate system to angles instead of xy. Makes it easier to apply zenith optimization.

% Define optimization settings
opt.maxIter=1000;
opt.OutputFcn=[];
opt.TolFun = 0.025;
opt.TolX = inf;
opt.Display='none';


x0 = double([regs.FRMW.xfov regs.FRMW.yfov regs.DEST.txFRQpd(1) regs.FRMW.laserangleH regs.FRMW.laserangleV regs.FRMW.xoffset]);
xL = [40 40 4000   -3 -3 0];
xH = [90 90 6000   3  3 0];

[e,v,xF,yF]=errFunc(rpt,regs,x0,verbose);

[xbest,minerr]=fminsearchbnd(@(x) errFunc(rpt,regs,x,0),x0,xL,xH,opt);
% [xbest,minerr]=fminsearch(@(x) errFunc(rpt,regs,x,0),x0,opt);
outregs = x2regs(xbest,regs);

[e,v,xF,yF]=errFunc(rpt,outregs,xbest,verbose);
% 
% 
% for zen = 0
%     xbest(4) = single(zen);
%     outregs = x2regs(xbest,regs);
%     [e,v,xF,yF]=errFunc(rpt,outregs,xbest,verbose);
%     view([0,90])
%     
% end


[~,~,xF,yF]=Pipe.DIGG.ang2xy(angx,angy,outregs,Logger(),[]);

ok=~isnan(xF) & ~isnan(yF)  & d.i>1;
dnew.z = griddata(double(xF(ok)),double(yF(ok)),double(d.z(ok)),xg,yg);
dnew.i = griddata(double(xF(ok)),double(yF(ok)),double(d.i(ok)),xg,yg);
dnew.c = griddata(double(xF(ok)),double(yF(ok)),double(d.c(ok)),xg,yg);

end



function [e,v,xF,yF]=errFunc(rpt,rtlRegs,X,verbose)
%build registers array

rtlRegs = x2regs(X,rtlRegs);

[~,~,xF,yF]=Pipe.DIGG.ang2xy(rpt(:,:,2),rpt(:,:,3),rtlRegs,Logger(),[]);


rtd_=rpt(:,:,1)-rtlRegs.DEST.txFRQpd(1);


[sinx,cosx,~,cosy,sinw,cosw,sing]=Pipe.DEST.getTrigo(round(xF),round(yF),rtlRegs);

r= (0.5*(rtd_.^2 - rtlRegs.DEST.baseline2))./(rtd_ - rtlRegs.DEST.baseline.*sing);

z = r.*cosw.*cosx;
x = r.*cosy.*sinx;
y = r.*sinw;
v=cat(3,x,y,z);


e=Calibration.aux.evalGeometricDistortion(v,verbose);
if(verbose)
    fprintf('%f ',[X e]);
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

iterRegs.FRMW.xoffset=single(x(6));
% iterRegs.FRMW.yoffset=single(0);
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
