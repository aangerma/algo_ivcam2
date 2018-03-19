
function [e,v]=errFunc(s,rtlRegs,rtlLuts,X,verbose)
%build registers array

rtlRegs = Calibration.DFZ.x2regs(X,rtlRegs);

[xq,yq]= ang2xyLocal(s(:,:,1),s(:,:,2),rtlRegs,rtlLuts);

rtd_=s(:,:,3)-rtlRegs.DEST.txFRQpd(1);


[sinx,cosx,~,cosy,sinw,cosw,sing]=Pipe.DEST.getTrigo(xq,yq,rtlRegs);

r= (0.5*(rtd_.^2 - rtlRegs.DEST.baseline2))./(rtd_ - rtlRegs.DEST.baseline.*sing);

z = r.*cosw.*cosx;
x = r.*cosy.*sinx;
y = r.*sinw;
v=double(cat(3,x,y,z));


% [~,ve]=Calibration.aux.evalGeometricDistortion(v,verbose);
% %remove ray component from error
% n=v./sqrt(sum(v.^2,3));
% ve_=ve-n.*sum(ve.*n,3);
%  e = sqrt(mean(vec((sum(ve_.^2,3)))));
e = Calibration.DFZ.distanceMetrics([x(:) y(:) z(:)]',size(x),verbose);


end

function [xq,yq]= ang2xyLocal(angx,angy,regs,luts)
[x_,y_]=Pipe.DIGG.ang2xy(angx,angy,regs,Logger(),[]);
[x,y] = Pipe.DIGG.undist(x_,y_,regs,luts,Logger(),[]);
% % % [xq,yq] = Pipe.DIGG.ranger(x, y, regs);
% % % yq = double(yq);
% % % xq=double(xq)/4;
shift=double(regs.DIGG.bitshift);
xq = double(x)/2^shift;
yq = double(y)/2^shift;
end

