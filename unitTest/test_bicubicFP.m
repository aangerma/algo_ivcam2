%% bicubic interp test
gt_LUT = double(imread('cameraman.tif'))/7;% just so it will be double
gt_LUT = gt_LUT(:,1:2:end); %make it uneven in rows and cols
% [X,Y] = meshgrid(-3:3);
% gt_LUT = peaks(X,Y);


NUM_BIN_x = size(gt_LUT,2);
NUM_BIN_y = size(gt_LUT,1);

startx=0;
endx = NUM_BIN_x-1;
starty=0;
endy = NUM_BIN_y-1;

[X,Y] = meshgrid(linspace(startx,endx,NUM_BIN_x),linspace(starty,endy,NUM_BIN_y));
dx = X(1,2)-X(1,1);
dy = Y(2,1)-Y(1,1);

x_interp_coef = 2^2;
y_interp_coef = 2^3;

[x_grid_gt,y_grid_gt] = meshgrid(linspace(startx,endx,NUM_BIN_x*x_interp_coef), linspace(starty,endy,NUM_BIN_y*y_interp_coef));

%% FIRMWARE
shift = 20;
LUT = int64(gt_LUT*2^shift);
fx = int64((1/dx)*2^shift);
fy = int64((1/dy)*2^shift);
x_grid = int64(x_grid_gt*2^shift);
y_grid = int64(y_grid_gt*2^shift);
shift_uint8 = uint8(shift);

%% HARDWARE

lutobj = Pipe.DIGG.bicubicFP(LUT,fx,fy,shift_uint8);
resLUT = lutobj.at(x_grid,y_grid);


%% plot res
res_interp = interp2(X,Y,gt_LUT,x_grid_gt,y_grid_gt,'cubic');
resLUT_shift = double(resLUT)./(2^shift);
dif = abs(res_interp-double(resLUT_shift));

% REMOVE EDGES!!!
dif = dif(y_interp_coef+2:end-y_interp_coef-1,x_interp_coef+2:end-x_interp_coef-1);

figure(54443);
subplot(2,2,[1 3]);
imagesc(dif);
[m,i] = max(dif(:));
[I,J] = ind2sub(size(dif),i);
% title(['WITHOUT EDGES!! max diff =' num2str(m) ' at x=' num2str(J) ' y=' num2str(I) '     bitshift = ' num2str(shift)]);
title(['WITHOUT EDGES!! max diff =' num2str(m) '     bitshift = ' num2str(shift)]);

a(1) = subplot(222);
imagesc(resLUT_shift);
title('my interp')
a(2) = subplot(224);
imagesc(res_interp);
title('orig interp')
linkaxes(a);


