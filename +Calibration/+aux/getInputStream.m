function stream=getInputStream(d,regs,luts)%#ok


z=double(d.z)/2^double(regs.GNRL.zMaxSubMMExp);
z(z==0)=nan;
rv = z(Utils.indx2col(size(z),[1 1]*5));
z = reshape(nanmedian(rv),size(z));
 

sz = size(z);
[sinx,cosx,singy,cosy,sinw,cosw,sing]=Pipe.DEST.getTrigo(sz,regs);%#ok

[yg,xg]=ndgrid(1:sz(1),1:sz(2));

if(regs.DEST.depthAsRange)
r=z;
else
r = z./(cosw.*cosx);
end
b = -2*r;
c = -double(2*r*regs.DEST.baseline.*sing + regs.DEST.baseline2);
stream.rtd = 0.5*(-b+sqrt(b.*b-4*c));
stream.rtd = stream.rtd+regs.DEST.txFRQpd(1);

if(regs.DIGG.sphericalEn)
yy = double(yg-1);
xx=double((xg-1)*4);
xx = xx-double(regs.DIGG.sphericalOffset(1));
yy = yy-double(regs.DIGG.sphericalOffset(2));
xx = xx*2^10;%bitshift(xx,+12-2);
yy = yy*2^12;%bitshift(yy,+12);
xx = xx/double(regs.DIGG.sphericalScale(1));
yy = yy/double(regs.DIGG.sphericalScale(2));

stream.angx = int32(xx);
stream.angy = int32(yy);
else
[stream.angx,stream.angy]=Pipe.CBUF.FRMW.xy2ang(xg,yg,regs);
end
stream.ir = double(d.i);
ii = double(d.i);
ii(ii==0)=nan;

[p,bsz]=detectCheckerboardPoints(normByMax(ii));
it = @(k) interp2(xg,yg,double(k),reshape(p(:,1),bsz-1),reshape(p(:,2),bsz-1)); % Used to get depth and ir values at checkerboard locations.
stream.s = cat(3,it(stream.angx),it(stream.angy),it(stream.rtd),it(stream.ir));
stream.p=reshape(p,[bsz-1 2]);
%{
[xq,yq]= ang2xyLocal(stream.s(:,:,1),stream.s(:,:,2),regs,luts);
[sinx,cosx,singy,cosy,sinw,cosw,sing]=Pipe.DEST.getTrigo(xq,yq,regs)
coswx=cosw.*cosx;
z = stream.s(:,:,3)/2.*coswx
%}
end