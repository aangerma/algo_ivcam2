
function [e,v]=errFunc(s,rtlRegs,rtlLuts,X,verbose)
    tileSizeMM = 30;
%build registers array

rtlRegs = Calibration.DFZ.x2regs(X,rtlRegs);

[xq,yq]= ang2xyLocal(s(:,:,1),s(:,:,2),rtlRegs,rtlLuts);

rtd_=s(:,:,3)-rtlRegs.DEST.txFRQpd(1);


[sinx,cosx,~,cosy,sinw,cosw,sing]=Pipe.DEST.getTrigo(xq,yq,rtlRegs);

r= (0.5*(rtd_.^2 - rtlRegs.DEST.baseline2))./(rtd_ - rtlRegs.DEST.baseline.*sing);

z = r.*cosw.*cosx;
x = r.*cosw.*sinx;
y = r.*sinw;
v=double(cat(3,x,y,z));


% [~,ve]=Calibration.aux.evalGeometricDistortion(v,verbose);

o = optGrid(size(v),tileSizeMM);

o_ = rigidFit(v,o);
% e = Calibration.DFZ.distanceMetrics([x(:) y(:) z(:)]',size(x),verbose);
e = o_-v;
% %remove ray component from error
 n=v./sqrt(sum(v.^2,3));
 e_=e-n.*sum(e.*n,3);
 e = sqrt(mean(vec((sum(e_.^2,3)))));


end

function g = optGrid(sz,tileSizeMM)
   
h=sz(1);
w=sz(2);

[oy,ox]=ndgrid(linspace(-1,1,h)*(h-1)*tileSizeMM/2,linspace(-1,1,w)*(w-1)*tileSizeMM/2);
g = cat(3,ox,oy,zeros(h,w));

end

function p2o = rigidFit(p1,p2)
    p1v=reshape(p1,[],3)';
    p2v=reshape(p2,[],3)';
% finds optimal rot and translation. Returns the error.
c = mean(p1v,2);
p1_=p1v-mean(p1v,2);
p2_=p2v-mean(p2v,2);

%shift to center, find rotation along PCA
[u,~,vt]=svd(p1_*p2_');
rotmat=u*vt';
p2o = rotmat*p2_+c; 
p2o = reshape(p2o',size(p1));
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

