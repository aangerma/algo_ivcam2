t = 'XGA';
res = [1024 768];
filesI = dirFiles('C:\temp\for_yoni\xga_checker_board_1m', '*.bini',1);
filesZ = dirFiles('C:\temp\for_yoni\xga_checker_board_1m', '*.bin',1);
readFiles =@(p,t)(cellfun(@(x)(du.formats.readBinFile(x,res,t)),p,'uni',0));
i=readFiles(filesI,8);
z=readFiles(filesZ,16);
framesCheckerXGA = struct('i',i(:),'z',z(:))

 
filesI = dirFiles('C:\temp\for_yoni\235_xga_ir_depth_1.85m_10p', '*.bini',1);
filesZ = dirFiles('C:\temp\for_yoni\235_xga_ir_depth_1.85m_10p', '*.bin',1);
readFiles =@(p,t)(cellfun(@(x)(du.formats.readBinFile(x,res,t)),p,'uni',0));
i=readFiles(filesI,8);
z=readFiles(filesZ,16);
frames10pXGA = struct('i',i(:),'z',z(:))

 
t = 'VGA';
res = [640 480];
filesI = dirFiles('C:\temp\for_yoni\vga_checker_board_1m', '*.bini',1);
filesZ = dirFiles('C:\temp\for_yoni\vga_checker_board_1m', '*.bin',1);
readFiles =@(p,t)(cellfun(@(x)(du.formats.readBinFile(x,res,t)),p,'uni',0));
i=readFiles(filesI,8);
z=readFiles(filesZ,16);
framesCheckerVGA = struct('i',i(:),'z',z(:))

 
filesI = dirFiles('C:\temp\for_yoni\235_vga_ir_depth_2.8m_10p', '*.bini',1);
filesZ = dirFiles('C:\temp\for_yoni\235_vga_ir_depth_2.8m_10p', '*.bin',1);
readFiles =@(p,t)(cellfun(@(x)(du.formats.readBinFile(x,res,t)),p,'uni',0));
i=readFiles(filesI,8);
z=readFiles(filesZ,16);
frames10pVGA = struct('i',i(:),'z',z(:))

 
hw = HWinterface();
hw.startStream(false, [768 1024]);
hw.getIntrinsics;
params.camera.zK = hw.getIntrinsics;
params.camera.zMaxSubMM = 4;
params.mask.rectROI.flag = false;
params.mask.circROI.flag = false;
params.mask.checkerBoard.flag = false;
params.mask.detectDarkRect.flag = false;

 
[~, ~,dbg10pXGA] = Validation.metrics.avgImage(frames10pXGA, params);
[~, ~,dbg10pVGA] = Validation.metrics.avgImage(frames10pVGA, params);
[~, ~,dbgCheckerXGA] = Validation.metrics.avgImage(framesCheckerXGA, params);
[~, ~,dbgCheckerVGA] = Validation.metrics.avgImage(framesCheckerVGA, params);
figure; hold on;
plot(dbg10pXGA.irIntensityForFrame);
plot(dbg10pVGA.irIntensityForFrame);
plot(dbgCheckerXGA.irIntensityForFrame);
plot(dbgCheckerVGA.irIntensityForFrame);
grid minor;
title irintensity;
legend('10pXGA', '10pVGA', 'CheckerXGA','CheckerVGA');

 
 
figure; hold on;
plot(dbg10pXGA.zAvg);
plot(dbg10pVGA.zAvg);
plot(dbgCheckerXGA.zAvg);
plot(dbgCheckerVGA.zAvg);
grid minor;
title meanZ;
legend('10pXGA', '10pVGA', 'CheckerXGA','CheckerVGA');

N = length(frames);
gridInterDist10pXGA = zeros(1,N);
gridInterDist10pVGA = zeros(1,N);
gridInterDistCheckerXGA = zeros(1,N);
gridInterDistCheckerVGA = zeros(1,N);
params.target.target = 'checkerboard';
params.target.squareSize = 50;
for i=20:N
    gridInterDistCheckerXGA(i) = Validation.metrics.gridInterDistance(framesCheckerXGA(i),params);
%     gridInterDistCheckerVGA(i) = Validation.metrics.gridInterDistance(framesCheckerVGA(i),params);
   
end

figure; hold on;
plot(gridInterDistCheckerXGA);
plot(gridInterDistCheckerVGA);
grid minor;
title gridInterDist;
legend('CheckerXGA','CheckerVGA');

 
params.mask.circROI.flag = true;
params.mask.radius = 0.1;

N = length(frames);
zFillRate10pXGA = zeros(1,N);
zFillRate10pVGA = zeros(1,N);
zFillRateCheckerXGA = zeros(1,N);
zFillRateCheckerVGA = zeros(1,N);
for i=1:N
    zFillRate10pXGA(i) = Validation.metrics.zFillRate(frames10pXGA(i),params);
    zFillRate10pVGA(i) = Validation.metrics.zFillRate(frames10pVGA(i),params);
    zFillRateCheckerXGA(i) = Validation.metrics.zFillRate(framesCheckerXGA(i),params);
    zFillRateCheckerVGA(i) = Validation.metrics.zFillRate(framesCheckerVGA(i),params);
end

 
figure; hold on;
plot(zFillRate10pXGA);
plot(zFillRate10pVGA);
plot(zFillRateCheckerXGA);
plot(zFillRateCheckerVGA);
grid minor;
title zFillRate;
legend('10pXGA', '10pVGA', 'CheckerXGA','CheckerVGA');
grid minor;
title fillRate;
