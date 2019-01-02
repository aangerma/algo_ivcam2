prefix = {'example_1';'example_2'};
for m = 1:2

H = 640;
V = [360 480];

zNorm = [8 4];
[xim,yim] = meshgrid(0:H-1,0:V(m)-1);
z = uint16((2000+(xim+yim)/640*50)*zNorm(m));
IR = imread('C:\Users\tmund\Desktop\K_Matrix_Files\Image.png');
IR = rgb2gray(IR);
IR = imresize(IR,size(z));
K{1} = [500   0 319.5;
       0 500 179.5;
       0 0 1];
K{2} = [566    0  300
        0 -536  178
        0    0    1];

zim = double(z)/zNorm(m);

xim = xim';
yim = yim';
zim = zim';


P = [xim(:)'.*zim(:)';yim(:)'.*zim(:)';zim(:)'];

XYZ = K{m}\P;

X = XYZ(1,:);
Y = XYZ(2,:);
Z = XYZ(3,:);

plot3(X,Y,Z)
hold on
% 
 
% Save zNorm and K in a log file:
fid = fopen([prefix{m},'_K_and_zNorm.txt'],'wt');
fprintf(fid,'K matrix:\n');
for ii = 1:size(K{m},1)
    fprintf(fid,'%4g\t',K{m}(ii,:));
    fprintf(fid,'\n');
end
fprintf(fid,'zNorm = %d\n',zNorm(m));
fclose(fid);
% Save z and IR as bin files
fid = fopen([prefix{m},'_ir.bin'],'w');
fwrite(fid,reshape(transpose(IR),[],1),'uint8')
fclose(fid);

fid = fopen([prefix{m},'_z.bin'],'w');
fwrite(fid,reshape(transpose(z),[],1),'uint16')
fclose(fid);


fid = fopen([prefix{m},'_X_gt_single.bin'],'w');
fwrite(fid,reshape(single(X),[],1),'single')
fclose(fid);

fid = fopen([prefix{m},'_Y_gt_single.bin'],'w');
fwrite(fid,reshape(single(Y),[],1),'single')
fclose(fid);

fid = fopen([prefix{m},'_Z_gt_single.bin'],'w');
fwrite(fid,reshape(single(Z),[],1),'single')
fclose(fid);


end