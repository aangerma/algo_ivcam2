function [outregs,minerr,eFit,dnew]=calibDFZ(d,regs,verbose,eval)
if(~exist('eval','var'))
    eval=false;
end
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

imz = double(d.z);
imz(imz==0)=nan;
N=3;
imv = imz(Utils.indx2col(size(imz),[N N]));
bd = vec(isnan(imz));
imz(bd)=nanmedian_(imv(:,bd));
d.z = imz;

%calc RTD 
if ~regs.DEST.depthAsRange
    [~,r] = Pipe.z16toVerts(d.z,regs);
else
    r = double(d.z)/bitshift(1,regs.GNRL.zMaxSubMMExp);
end

[~,~,~,~,~,~,sing]=Pipe.DEST.getTrigo(size(r),regs);
C=2*r*regs.DEST.baseline.*sing- regs.DEST.baseline2;
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

%rtd,phi,theta
rpt=cat(3,it(rtd),it(angx),it(angy)); % Convert coordinate system to angles instead of xy. Makes it easier to apply zenith optimization.

% Define optimization settings

% Only from here we can change params that affects the 3D calculation (like
% baseline, gaurdband, ...
% regs.DEST.baseline = single(40);
% regs.DEST.baseline2 = single(single(regs.DEST.baseline).^2);

%%

angXShift = 0;
x0 = double([regs.FRMW.xfov regs.FRMW.yfov regs.DEST.txFRQpd(1) regs.FRMW.laserangleH regs.FRMW.laserangleV angXShift]);
% x0 = double([63.51	60.76	50.80	0.64	0.44 0]);
xL = [40 40 4000   -3 -3 -0];
xH = [90 90 6000    3  3  0];
regs = x2regs(x0,regs);
[e,eFit]=errFunc(rpt,regs,x0,0);
if eval 
    outregs = [];
    minerr = e;
    dnew =[];
    return
end
printErrAndX(x0,e,eFit,'X0:',verbose)

opt.maxIter=10000;
opt.OutputFcn=[];
opt.TolFun = 1e-6;
opt.TolX = 1e-3;
opt.Display='none';
[xbest,~]=fminsearchbnd(@(x) errFunc(rpt,regs,x,0),x0,xL,xH,opt);
[xbest,minerr]=fminsearchbnd(@(x) errFunc(rpt,regs,x,0),xbest,xL,xH,opt);
% [xbest,minerr]=fminsearch(@(x) errFunc(rpt,regs,x,0),x0,opt);
outregs = x2regs(xbest,regs);
rpt_new = cat(3,it(rtd),it(angx+xbest(6)),it(angy));
[e,eFit]=errFunc(rpt_new,outregs,xbest,1);
printErrAndX(xbest,e,eFit,'Xfinal:',verbose)

[zNewVals,xF,yF]=rpt2z(cat(3,rtd,angx+xbest(6),angy),outregs);

ok=~isnan(xF) & ~isnan(yF)  & d.i>1;
dnew.z = griddata(double(xF(ok)),double(yF(ok)),double(zNewVals(ok)),xg,yg);
dnew.i = griddata(double(xF(ok)),double(yF(ok)),double(d.i(ok)),xg,yg);
% dnew.c = griddata(double(xF(ok)),double(yF(ok)),double(d.c(ok)),xg,yg);

end


function [z,xF,yF] = rpt2z(rpt,rtlRegs)

[~,~,xF,yF]=Pipe.DIGG.ang2xy(rpt(:,:,2),rpt(:,:,3),rtlRegs,Logger(),[]);
rtd_=rpt(:,:,1)-rtlRegs.DEST.txFRQpd(1);
[~,cosx,~,~,~,cosw,sing]=Pipe.DEST.getTrigo(round(xF),round(yF),rtlRegs);
r = (0.5*(rtd_.^2 - rtlRegs.DEST.baseline2))./(rtd_ - rtlRegs.DEST.baseline.*sing);
if rtlRegs.DEST.depthAsRange
    z = r;
else
    z = r.*cosw.*cosx;
end
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
end
function printErrAndX(X,e,eFit,preSTR,verbose)
if verbose 
    fprintf('%-8s',preSTR);
    fprintf('%4.2f ',X);
    fprintf('eAlex: %.2f ',e);
    fprintf('eFit: %.2f ',eFit);
    fprintf('\n');
end
end
function rtlRegs = x2regs(x,rtlRegs)


iterRegs.FRMW.xfov=single(x(1));
iterRegs.FRMW.yfov=single(x(2));
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
