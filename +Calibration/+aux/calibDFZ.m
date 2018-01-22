function r2zFromImg(d,regs)



im = double(d.i);
im(im==0)=nan;
N=3;
imv = im(Utils.indx2col(size(im),[N N]));
bd = vec(isnan(im));
im(bd)=nanmedian(imv(:,bd));
%      im=reshape(nanmedian(imv),size(im));

p = detectCheckerboardPoints(normByMax(im));

[~,r] = Pipe.z16toVerts(d.z,regs);

xbest=fminsearch(@(x) errFunc(r,p,x),x0);
end


function e=errFunc(r,p,X)
regs=x2regs(X);
trigoRegs = Pipe.DEST.FRMW.trigoCalcs(regs);
[~,~,~,~,~,~,sing]=Pipe.DEST.getTrigo(size(r),regs);
C=r*regs.DEST.baseline.*sing- regs.DEST.baseline2;
rtd=r+sqrt(r.^2-C);
[z,r,x,y]=Pipe.DEST.rtd2depth(rtd,trigoRegs);
[yg,xg]=ndgrid(1:size(r,1),1:size(r,2));
v=interp2(xg,yg,cat3(x,y,z,z*0),p(:,1),p(:,2));
e=Calibration.aux.evalGeometricDistortion(v);
end

function regs=x2regs(sz,x)
regs.FRMW.xfov=x(1);
regs.FRMW.yfov=x(2);
regs.FRMW.gaurdBandH=0;
regs.FRMW.gaurdBandV=0;
regs.FRMW.xres=sz(2);
regs.FRMW.yres=sz(1);
regs.FRMW.xoffset=0;
regs.FRMW.yoffset=0;
regs.FRMW.undistXfovFactor=1;
regs.FRMW.undistYfovFactor=1;
end