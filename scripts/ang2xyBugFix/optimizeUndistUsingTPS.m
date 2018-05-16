function [] = optimizeUndistUsingTPS(regs)
% Finds an optimal lut configuration so the error caused by bug will be
% fixed.


%{
1. Take an NxN grid in the image plane (and a bit outside).
2. Compute their angx angy.
3. Calculate the true X-Y after the fix. 
4. Compute the difference.
5. Feed into TPS using Ohad's method.


%}
[xs,ys] = meshgrid((-10):10:double(regs.FRMW.xres+10),-10:10:double(regs.FRMW.yres+10));
[angx,angy] = Pipe.CBUF.FRMW.xy2ang(xs,ys,regs);
[xd, yd] = localAng2xy(angx,angy,regs,true);
subplot(121)
quiver(xs(:),ys(:),xd(:)-xs(:),yd(:)-ys(:),'autoscale','off');

[udistLUT,uxg,uyg,undistx,undisty]= myGenerateUndistTables([xs(:),ys(:)]',[xd(:),yd(:)]',double([regs.FRMW.yres,regs.FRMW.xres]));
luts.FRMW.undistModel = udistLUT;
[autogenRegs,autogenLuts] = Pipe.DIGG.FRMW.buildLensLUT(regs,luts);
regs = Firmware.mergeRegs(regs,autogenRegs);
luts = Firmware.mergeRegs(luts,autogenLuts);

[ xnew,ynew ] = Pipe.DIGG.undist( xs*2^15,ys*2^15,regs,luts,[],[] );
xnew = single(xnew/2^15);
ynew = single(ynew/2^15);

subplot(122)
quiver(xnew(:),ynew(:),xd(:)-xnew(:),yd(:)-ynew(:),'autoscale','off');

eMatPre = sqrt((xs-xd).^2 + (ys-yd).^2);
eMatPost = sqrt((xnew-xd).^2 + (ynew-yd).^2);

ePre = norm(eMatPre,'fro')
ePost = norm(eMatPost,'fro')
subplot(121)
imagesc(eMatPre);colorbar;
subplot(122)
imagesc(eMatPost);colorbar;


% Evaluate on all pixels
[angx,angy] = meshgrid(linspace(-2047,2047,500),linspace(-2047,2047,500));
[~,~,x,y] = Pipe.DIGG.ang2xy(angx,angy,regs,[],[]);
[xF,yF] = localAng2xy(angx,angy,regs,true);
[ xund,yund ] = Pipe.DIGG.undist( x*2^15,y*2^15,regs,luts,[],[] );
xund = single(xund/2^15);
yund = single(yund/2^15);

eMatPre = sqrt((x-xF).^2 + (y-yF).^2);
eMatPost = sqrt((xund-xF).^2 + (yund-yF).^2);
subplot(121)
imagesc(eMatPre);colorbar;
subplot(122)
imagesc(eMatPost);colorbar;

% Calculate error only on image pixels.
inImage = and(and(and(xF>=0,xF<=640),yF>=0),yF<=480);
eMatPre(~(inImage)) = 0;
eMatPost(~(inImage)) = 0;
tabplot;mesh(xF,yF,eMatPre);colorbar;
tabplot;mesh(xF,yF,eMatPost);colorbar;

mean(eMatPre(inImage))
mean(eMatPost(inImage))


% 
% figure
% plot(x(:),y(:),'*');
% hold on
% plot(single(xnew(:)),single(ynew(:)),'*');
% rectangle('position',[0 0 double(regs.GNRL.imgHsize-1) double(regs.GNRL.imgVsize-1)])
% figure
% imagesc(y-single(ynew)),colorbar


end
