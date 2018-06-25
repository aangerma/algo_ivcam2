%{ 
Ang2XY is mapping dsm angles to the image plane. 
The bug makes it so the mapping is wrong. 

%} 

clear, close all
% Load some fw
fw = Pipe.loadFirmware('\\tmund-MOBL1\C$\source\algo_ivcam2\+Calibration\initScript');
regs2.FRMW.guardBandV = single(0);
fw.setRegs(regs2,'');
[regs,luts] = fw.get();
% Create a grid of angles:
maxAng = 2047;
[angx,angy] = meshgrid([-maxAng:10:maxAng],[-maxAng:10:maxAng]);
% Show that the real ang2xy function is the same as the straight forward
% version:
[~,~,x,y] = Pipe.DIGG.ang2xy(angx,angy,regs,[],[]); % Ang2xy from Pipe
[xSF,ySF] = localAng2xy(angx,angy,regs,false);      % Ang2xy Straight Forward - should be identical to Pipe
[xFixed,yFixed] = localAng2xy(angx,angy,regs,true);      % Ang2xy Straight Forward - should be identical to Pipe

subplot(121)
imagesc(sqrt((x-xSF).^2+(y-ySF).^2)),colorbar,title('Pixel Distance Between Pipe and Straight Forward')
% One can see the difference is only quantization noise and doesn't raise
% above 0.04 pixels.
subplot(122)
imagesc(sqrt((x-xFixed).^2+(y-yFixed).^2)),colorbar,title('Pixel Distance Between Straight Forward Before and After Fix')
% The difference before and after the fix is zero along th axis, but can
% reach up to 13 pixels in the image corners with xfov of 70 and yfov of
% 52.

%%  Why do I think my fix is right? Lets take a line in space, calculate the relevant angx and angy angles, and project to the image plane. Verify they are still a line in the image plane.
p1 = [-2,5,5]';
p2 = [-2,-5,5]';
t = 0:0.01:1;
points = p1*t+p2*(1-t);
% For each point, we can calculate the angles of the mirror by:
% Normlizing to unit norm vectors.
% The normal of the mirror is the average vector between the vectors and
% [0,0,1].
% Extract the angles. 
% Map to the range.
points_normed = normc(points);
mirror_normal = normc(points_normed+[0,0,1]');
angyDeg = asind(mirror_normal(2,:));
angxDeg = asind(mirror_normal(1,:)./cosd(angyDeg));
angyQ = angyDeg/(regs.FRMW.yfov/4)*maxAng;
angxQ = angxDeg/(regs.FRMW.xfov/4)*maxAng;
[xImSF,yImSF] = localAng2xy(angxQ,angyQ,regs,false);      % Ang2xy Straight Forward - should be identical to Pipe
[xImFixed,yImFixed] = localAng2xy(angxQ,angyQ,regs,true);      % Ang2xy Straight Forward - should be identical to Pipe

figure
plot(xImSF(:),yImSF(:),'-*');
hold on
plot(xImFixed(:),yImFixed(:),'-*');
rectangle('position',[0 0 double(regs.GNRL.imgHsize) double(regs.GNRL.imgVsize)])
title('Vertical Line in space is mapped to a nonlinear curve in the image plane')
legend({'Before Fix';'After Fix'})


%% I shall try and fix the error using the undistort block. 
% We would like to transfer the points (x,y) to their corresponding
% (xFixed,yFixed)
s = [vec(x),vec(y)]';
d = [vec(xFixed),vec(yFixed)]';
% Show displacement:
quiver(s(1,:),s(2,:),d(1,:)-s(1,:),d(2,:)-s(2,:));
title('Displacement Vector Field');



[udistLUT,uxg,uyg,undistx,undisty]=Calibration.aux.generateUndistTables(s,d,[double(regs.GNRL.imgHsize) double(regs.GNRL.imgVsize)]);

[yg,xg]=ndgrid(0:size(im,1)-1,0:size(im,2)-1);

undistF = @(v) griddata(xg+interp2(uxg,uyg,undistx,xg,yg),yg+interp2(uxg,uyg,undisty,xg,yg),double(v),xg,yg);
if(verbose)
    %%
    figure(sum(mfilename));
    clf;
    subplot(121)
    imagesc(im);
    axis image
    colormap gray
    hold on
    quiver(s(1,:),s(2,:),d(1,:)-s(1,:),d(2,:)-s(2,:));
    quiver(uxg,uyg,undistx,undisty);
    hold off
    title(sprintf('Projective error: rms=%f,max=%f',e,max(sqrt(sum((d-s).^2,2)))));
    subplot(122)
    
    quiver(s(1,:)*0,s(2,:)*0,d(1,:)-s(1,:),d(2,:)-s(2,:),0);
    
    axis square
end