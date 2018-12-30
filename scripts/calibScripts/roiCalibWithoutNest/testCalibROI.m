% Create a spherical image with 3 levels - 0, 0.5 and
% 1
fw = Pipe.loadFirmware('C:\source\algo_ivcam2\+Calibration\releaseConfigCalib');
% regs2.GNRL.imgVsize = uint16(480);
% fw.setRegs(regs2,'');
regs = fw.get();

white = ones(360,640);
figure;
proj =  roipoly(white); close;
plusNoise = imdilate(proj,strel('square',10));
im = double(proj);
im(plusNoise>proj) = 0.5;
figure, tabplot; imagesc(im)

% Get the angx/angy
[yg,xg]=ndgrid(0:size(proj,1)-1,0:size(proj,2)-1);
yy = double(yg);
xx = double((xg)*4);
xx = xx-double(regs.DIGG.sphericalOffset(1));
yy = yy-double(regs.DIGG.sphericalOffset(2));
xx = xx*2^10;%bitshift(xx,+12-2);
yy = yy*2^12;%bitshift(yy,+12);
xx = xx/double(regs.DIGG.sphericalScale(1));
yy = yy/double(regs.DIGG.sphericalScale(2));

angx = single(xx);
angy = single(yy);
angx = angx(proj);
angy = angy(proj);


% Save the x-y of the image plane without margins
[x,y] = Calibration.aux.ang2xySF(angx,angy,regs,[],1);
tabplot; plot(x,y,'*r');
hold on;
rectangle('position',[0 0 double(regs.GNRL.imgHsize) double(regs.GNRL.imgVsize)])

% Apply the calibROI function
calibParams.roi.extraMarginT = 0;
calibParams.roi.extraMarginB = 0;
calibParams.roi.extraMarginL = 0;
calibParams.roi.extraMarginR = 0;
calibParams.roi.useExtraMargins = 0;
calibParams.fovExpander.valid = 0;
mregs = Calibration.roi.calibROI(im,im,0.5,regs,calibParams,[]);
% Apply the fixed ang2xy with the correct margin ad view the result
fw.setRegs(mregs,'');
regs = fw.get();

[x,y] = Calibration.aux.ang2xySF(angx,angy,regs,[],1);
figure;tabplot; plot(x,y,'*b');
hold on;
rectangle('position',[0 0 double(regs.GNRL.imgHsize) double(regs.GNRL.imgVsize)])



