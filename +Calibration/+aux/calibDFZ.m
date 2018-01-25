function regs=calibDFZ(d,regs,verbose)
if(~exist('verbose','var'))
    verbose=true;
end

%some filtering
im = double(d.i);
im(im==0)=nan;
N=3;
imv = im(Utils.indx2col(size(im),[N N]));
bd = vec(isnan(im));
im(bd)=nanmedian(imv(:,bd));
[p,bsz] = detectCheckerboardPoints(normByMax(im));

[~,r] = Pipe.z16toVerts(d.z,regs);
[~,~,~,~,~,~,sing]=Pipe.DEST.getTrigo(size(r),regs);
C=r*regs.DEST.baseline.*sing- regs.DEST.baseline2;
rtd=r+sqrt(r.^2-C);
rtd=conv2(rtd,fspecial('gaussian',[10 10],5),'same');
[yg,xg]=ndgrid(1:size(rtd,1),1:size(rtd,2));
it = @(k) interp2(xg,yg,k,reshape(p(:,1),bsz-1),reshape(p(:,2),bsz-1));

opt.maxIter=1000;
opt.OutputFcn=[];
if(verbose)
    opt.Display='iter';
end

x0 = double([regs.FRMW.xfov regs.FRMW.yfov regs.DEST.txFRQpd(1)]);
xL = [20 20 4000];
xH = [90 90 10000];
xbest=fminsearchbnd(@(x) errFunc(rtd,it,x),x0,xL,xH,opt);
[~,v]=errFunc(rtd,it,xbest);
regs = x2regs(xbest);
end


function [e,v]=errFunc(rtd,it,X)
regs=x2regs(size(rtd),X);
trigoRegs = Pipe.DEST.FRMW.trigoCalcs(regs);
trigoRegs.MTLB.fastApprox=true(1,8);
trigoRegs.DEST.hbaseline=false;
trigoRegs.DEST.baseline=30;
trigoRegs.DEST.baseline2=trigoRegs.DEST.baseline^2;
trigoRegs.DEST.depthAsRange=false;
[z,~,x,y]=Pipe.DEST.rtd2depth(rtd,trigoRegs);
v=cat(3,it(x),it(y),it(z));
e=Calibration.aux.evalGeometricDistortion(v);
end

function regs=x2regs(sz,x)
regs.FRMW.xfov=x(1);
regs.FRMW.yfov=x(2);
regs.FRMW.gaurdBandH=0;
regs.FRMW.gaurdBandV=0;
regs.FRMW.xres=sz(2);
regs.FRMW.yres=sz(1);
regs.FRMW.marginL=0;
regs.FRMW.marginT=0;

regs.FRMW.xoffset=0;
regs.FRMW.yoffset=0;
regs.FRMW.undistXfovFactor=1;
regs.FRMW.undistYfovFactor=1;
regs.DEST.txFRQpd=[1 1 1]*x(3);
regs.DIGG.undistBypass = false;
regs.FRMW.undistXfovFactor=1;
regs.FRMW.undistYfovFactor=1;
regs.GNRL.rangeFinder=false;

end