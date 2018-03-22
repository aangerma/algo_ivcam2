N = 1000;
R = (N+1)/2;
[gx,gy] = meshgrid(1:N,1:N);
gy = gy - R; gx = gx - R;



im = zeros(N);
valid = (gx.^2 + gy.^2) <= R^2;
theta = atan2(gy,gx);
im(valid) = (cos(theta(valid))+1)/2;
im(~valid) = 1;
imagesc(im),colormap gray

imwrite(im,'calibRxTarget.jpg');