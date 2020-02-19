fnameIR = '\\ger\ec\proj\ha\RSG\SA_3DCam\Algorithm\Releases\IVCAM2.0\OnlineCalibration\Data\simulated_scene1\ZIRGB\I_GrayScale_640x480_0000.bin';
fnameZ = '\\ger\ec\proj\ha\RSG\SA_3DCam\Algorithm\Releases\IVCAM2.0\OnlineCalibration\Data\simulated_scene1\ZIRGB\Z_GrayScale_640x480_0000.bin';
fnameYUY2 = '\\ger\ec\proj\ha\RSG\SA_3DCam\Algorithm\Releases\IVCAM2.0\OnlineCalibration\Data\simulated_scene1\ZIRGB\YUY2_YUY2_1920x1080_0000.bin';

f = fopen(fnameIR,'w');
fwrite(f,uint8(vec(frame.i')),'uint8');
fclose(f);

f = fopen(fnameZ,'w');
fwrite(f,uint16(vec(frame.z')),'uint16');
fclose(f);

f = fopen(fnameYUY2,'w');
fwrite(f,uint16(vec(frame.yuy2')),'double');
fclose(f);




imgSize = [480,640];
imgSize = [1080,1920];
I = io.readGeneralBin(fnameYUY2,'double',imgSize);
figure,imagesc(I)
