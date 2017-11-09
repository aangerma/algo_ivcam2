function [autogenRegs,autogenLuts] = buildLensLUT(regs,luts)
shift = double(regs.DIGG.bitshift);
%
% if(regs.DIGG.undistBypass)
%     xLUT=uint32(0:1023);
%     yLUT=uint32(1024:2047);
%     fx=uint32(1);
%     fy=uint32(1);
%     x0=int32(0);
%     y0=int32(0);
% else
%{
     <-----distortionW---------->
(0,0)__      				  __
     \ \                     / /  ^
      \ \___________________/ /   |
      |                       |   |
      |   +---------------+   |   |
      |   |               |   |   |
      |   |   displament  |   | distortionH
      |   |     map       |   |   |
      |   |               |   |   |
      |   +---------------+   |   |
      /  ___________________  \   |
     /__/                   \__\  v
%}

% if(~exist('xDisplacment','var') || ~exist('yDisplacment','var'))
%     [xDisplacment,yDisplacment]=lensDisplacmentModel(regs);
% end
%% caluculate total pixel area effected by undistort
N = 32;%LUT size
limang = bsxfun(@times,[1 1;-1 1;1 -1;-1 -1;0 1;0 -1],[ 2047 2047] );
[limx,limy] = Pipe.DIGG.ang2xy(limang(:,1),limang(:,2),regs,Logger(),[]);
toint32 = @(x) int32(x*2^shift);
limx = double(limx)./(2^shift);
limy = double(limy)./(2^shift);
[x0,x1]=minmax(limx);
[y0,y1]=minmax(limy);
x0=floor(x0)-1;
y0=floor(y0)-1;
x1=ceil(x1)+1;
y1=ceil(y1)+1;


distortionH=y1-y0;
distortionW=x1-x0;
fx = (N-1)/distortionW;
fy = (N-1)/distortionH;
if(~isfield(luts,'FRMW') || ~isfield(luts.FRMW,'yLensModel') || ~isfield(luts.FRMW,'xLensModel') || all([vec(luts.FRMW.xLensModel);vec(luts.FRMW.yLensModel)]==0))
    xDisplacment=zeros(32,'single');
    yDisplacment=zeros(32,'single');
else
    yDisplacment = reshape(typecast(luts.FRMW.yLensModel,'single'),32,32);
    xDisplacment = reshape(typecast(luts.FRMW.xLensModel,'single'),32,32);
    
end
%% renormalize
xDisplacment=xDisplacment*double(regs.GNRL.imgHsize);
yDisplacment=yDisplacment*double(regs.GNRL.imgVsize);
%%   build output ditortion grid
[odgy,odgx]=ndgrid(linspace(min(limy),max(limy),N),linspace(min(limx),max(limx),N));
%% build input distortion grid
[idgy,idgx]=ndgrid(linspace(0,double(regs.GNRL.imgVsize)-1,size(yDisplacment,1)),linspace(0,double(regs.GNRL.imgHsize)-1,size(xDisplacment,2)));
%% build output distotion grid
xLUT=idgx+interp2(idgx,idgy,xDisplacment,odgx,odgy,'spline');
yLUT=idgy+interp2(idgx,idgy,yDisplacment,odgx,odgy,'spline');



% end

%%

autogenRegs.DIGG.xShiftIn  = toint32(0);
autogenRegs.DIGG.yShiftIn  = toint32(0);
autogenRegs.DIGG.xScaleIn  = toint32(1);
autogenRegs.DIGG.yScaleIn  = toint32(1);
autogenRegs.DIGG.xShiftOut = toint32(0);
autogenRegs.DIGG.yShiftOut = toint32(0);
autogenRegs.DIGG.xScaleOut = toint32(1);
autogenRegs.DIGG.yScaleOut = toint32(1);

autogenRegs.DIGG.undistFx = uint32(toint32(fx));
autogenRegs.DIGG.undistFy = uint32(toint32(fy));
autogenRegs.DIGG.undistX0 = toint32(x0);
autogenRegs.DIGG.undistY0 = toint32(y0);

autogenLuts.DIGG.xLensModel = toint32(xLUT(:));
autogenLuts.DIGG.yLensModel = toint32(yLUT(:));

%
%
%
% if(regs.MTLB.debug)
%     %%
%     dn = @(x) bitshift(x+2^(shift-1),-shift);
%     regs = Firmware.mergeRegs(regs,autogenRegs);
%     n=-(2^11-1):200:(2^11-1);
%
%     [yaQ,xaQ]=ndgrid(n,n);
%     [xi,yi]= Pipe.DIGG.ang2xy(yaQ,xaQ,regs,Logger(),[]);
%     [xo,yo]=Pipe.DIGG.undist(xi,yi,regs,autogenLuts,Logger(),[]);
%     xi=dn(xi);yi=dn(yi);
%     xo=dn(xo);yo=dn(yo);
%
%     figure(444567);clf
%     plot(xi,yi,'r.');
%     hold on
%     %      plot(xo,yo,'r.');
%     quiver(xi,yi,double(xo)-double(xi),double(yo)-double(yi),0);
%     hold off
%
%
%     axis tight
%     rectangle('pos',[0 0 regs.GNRL.imgHsize regs.GNRL.imgVsize]);
%     %     if(~regs.DIGG.undistBypass)
%     %         title(['lens LUT; distortCoeffs: ' num2str(c(:)')]);
%     %     end
%     drawnow;
% end

%%
%check that LUT covers the entire range
lx = min(limx):1:max(limx);
ly = min(limy):1:max(limy);
[yold,xold]=ndgrid(ly,lx);
yold=bitshift(int64(yold),15);
xold=bitshift(int64(xold),15);
% xold=2047;yold=2047;
X = int32(bitshift(int64(xold).*int64(autogenRegs.DIGG.xScaleIn),-15)) + autogenRegs.DIGG.xShiftIn;
Y = int32(bitshift(int64(yold).*int64(autogenRegs.DIGG.yScaleIn),-15)) + autogenRegs.DIGG.yShiftIn;

XX = int64(X) - int64(autogenRegs.DIGG.undistX0);
YY = int64(Y) - int64(autogenRegs.DIGG.undistY0);
xaddr = bitshift(XX*int64(autogenRegs.DIGG.undistFx),-15);
yaddr = bitshift(YY*int64(autogenRegs.DIGG.undistFy),-15);
assert(all(xaddr(:)>=0 & xaddr(:)<=bitshift(32,shift)-1));
assert(all(yaddr(:)>=0 & yaddr(:)<=bitshift(32,shift)-1));

end

% function [xd,yd]=lensDisplacmentModel(regs)
% N=32;
% %% ================== distortion model ======================
% % https://en.wikipedia.org/wiki/Distortion_(optics)
% 
% K = [...
%     1    0   0;
%     0    1   0;
%     0    0   1];
% 
% %     actualLens = [... %two last elements are the tangential...
% %         0.0091;
% %         0.0057;
% %         0.3134;
% %         -0.4344;
% %         0.3184;
% %         -0.0817;
% %         0;
% %         0];
% 
% actualLens = [... %two last elements are the tangential...
%     -0.0007;
%     0.0485;
%     -0.0270;
%     0.0523;
%     -0.0371;
%     0.0129;
%     0;
%     0];
% 
% 
% c = actualLens.*double(regs.FRMW.undistLensCurve);
% 
% % LUT range is defined on [2:31,2:31] so the bicubic interpolation
% % is applied without padding
% sp = linspace(-1,1,N-2);
% dsp = sp(2)-sp(1);
% sp = [sp(1)-dsp sp sp(end)+dsp];
% [ygrid,xgrid] = ndgrid(sp, sp);
% y = ygrid(:);
% x = xgrid(:);
% 
% %barrel/pincushin distort + Tangential distortion
% r = sqrt((x).^2+(y).^2);
% 
% A = [r r.^2 r.^3 r.^4 r.^5 r.^6];
% xx = (A*c(1:6)+1).*x + (c(8).*(r.^2+2.*x.^2)+2*c(7).*x.*y);
% yy = (A*c(1:6)+1).*y + (c(7).*(r.^2+2.*y.^2)+2*c(8).*x.*y);
% 
% %calibration matrix
% a = K*[xx.';yy.';ones(size(xx.'))];
% xnew = (vec(a(1,:)./a(3,:))+1)*.5;
% ynew = (vec(a(2,:)./a(3,:))+1)*.5;
% xd=reshape(xnew,[N N])*double(regs.GNRL.imgHsize);
% yd=reshape(ynew,[N N])*double(regs.GNRL.imgVsize);
% 
% end


