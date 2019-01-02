%% Check solution 1
fname = 'ir_uint8.bin';
type = 'uint8';
imgSize = [640,360];
f = fopen(fname,'rb');
buffer = fread(f,Inf,type);
fclose(f);

IR = reshape(buffer,imgSize)';


fname = 'z_uint16.bin';
type = 'uint16';
imgSize = [640,360];
f = fopen(fname,'rb');
buffer = fread(f,Inf,type);
fclose(f);

z = reshape(buffer,imgSize)';

fname = 'X_gt_single.bin';
type = 'single';
imgSize = [640,360];
f = fopen(fname,'rb');
buffer = fread(f,Inf,type);
fclose(f);

X = reshape(buffer,imgSize)';


fname = 'Y_gt_single.bin';
type = 'single';
imgSize = [640,360];
f = fopen(fname,'rb');
buffer = fread(f,Inf,type);
fclose(f);

Y = reshape(buffer,imgSize)';

fname = 'Z_gt_single.bin';
type = 'single';
imgSize = [640,360];
f = fopen(fname,'rb');
buffer = fread(f,Inf,type);
fclose(f);

Z = reshape(buffer,imgSize)';


K = [500   0 319.5;
       0 500 179.5;
       0 0 1];
zNorm = 8;

[xim,yim] = meshgrid(0:639,0:359);
zim = single(z(:)')/zNorm;
P = [xim(:)'.*zim;yim(:)'.*zim;zim];

XYZ = K\P;

XYZgt = [X(:),Y(:),Z(:)]';

err = max(abs(XYZ(:)-XYZgt(:)))

%% Check solution 2
fname = 'ir_uint8.bin';
type = 'uint8';
imgSize = [640,480];
f = fopen(fname,'rb');
buffer = fread(f,Inf,type);
fclose(f);

IR = reshape(buffer,imgSize)';


fname = 'z_uint16.bin';
type = 'uint16';
imgSize = [640,480];
f = fopen(fname,'rb');
buffer = fread(f,Inf,type);
fclose(f);

z = reshape(buffer,imgSize)';

fname = 'X_gt_single.bin';
type = 'single';
imgSize = [640,480];
f = fopen(fname,'rb');
buffer = fread(f,Inf,type);
fclose(f);

X = reshape(buffer,imgSize)';


fname = 'Y_gt_single.bin';
type = 'single';
imgSize = [640,480];
f = fopen(fname,'rb');
buffer = fread(f,Inf,type);
fclose(f);

Y = reshape(buffer,imgSize)';

fname = 'Z_gt_single.bin';
type = 'single';
imgSize = [640,480];
f = fopen(fname,'rb');
buffer = fread(f,Inf,type);
fclose(f);

Z = reshape(buffer,imgSize)';


K = [ 566	   0	 300	
   0	-536	 178	
   0	   0	   1	];
zNorm = 4;

[xim,yim] = meshgrid(0:639,0:479);
zim = single(z(:)')/zNorm;
P = [xim(:)'.*zim;yim(:)'.*zim;zim];

XYZ = K\P;

XYZgt = [X(:),Y(:),Z(:)]';

err = max(abs(XYZ(:)-XYZgt(:)))
