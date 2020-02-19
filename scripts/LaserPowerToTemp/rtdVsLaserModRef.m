minModprc = 0;
maxModprc = 1;
laserDelta = 1;
framesNum = 30;
res = [768,1024];%[480,640];
presetControl = 1;
outputPath = 'X:\Users\mkiperwa\delayVsLaserModRef\data';
maskParams = struct('roi',0.09, 'isRoiRect',0,'roiCropRect',0,'maskCenterShift', [0,0]);
mask = Validation.aux.getRoiCircle(res, maskParams);
% if ~exist('tec','var')
%     tc = TecController('COM4');
% end

%%
hw = HWinterface;
hw.startStream(0,res);
pause(0.5);



hw.setReg('DESTdepthAsRange',1);
hw.setReg('DESTbaseline$',single(0));
hw.setReg('DESTbaseline2',single(0));
hw.setPresetControlState(presetControl);
hw.cmd('mwd a00e18b8 a00e18bc ffff0000 // JFILinvMinMax');
hw.shadowUpdate;
z2mm = double(hw.z2mm);

s=hw.cmd('irb e2 09 01');
max_hex = sscanf(s,'Address: %*s => %s');
maxMod_dec = hex2dec(max_hex);
laserPtsDec = maxMod_dec*maxModprc:-laserDelta:maxMod_dec*minModprc;
%%
temps = nan(numel(laserPtsDec),1);
rtdInRoi = nan(numel(laserPtsDec),1);
irInRoi = nan(numel(laserPtsDec),1);
for k=1:numel(laserPtsDec)
    Calibration.aux.RegistersReader.setModRef(hw, laserPtsDec(k));
    tempStart = hw.getLddTemperature();
    frameBytes = Calibration.aux.captureFramesWrapper(hw, 'ZI', framesNum);
    tempEnd = hw.getLddTemperature();
    temps(k,1) = (tempStart+tempEnd)/2;
    im = Calibration.aux.convertBytesToFrames(frameBytes, res, [], false);
    frames = Calibration.aux.convertBytesToFrames(frameBytes, res, [], true);
%     figure(151284);tabplot; imagesc(frames.i); title(['IR image, ldd: ' num2str(temps(k,1)) ', mod ref dec: ' num2str(laserPtsDec(k))]); colorbar;
    frames.i(~mask) = nan;
    frames.z(~mask) = nan;
%     figure(151285);tabplot; imagesc(frames.z); title(['RTD image with mask, ldd: ' num2str(temps(k,1)) ', mod ref dec: ' num2str(laserPtsDec(k))]); colorbar;
%     figure(151286);tabplot; imagesc(frames.i); title(['IR image with mask, ldd: ' num2str(temps(k,1)) ', mod ref dec: ' num2str(laserPtsDec(k))]); colorbar;
    rtdInRoi(k,1) = nanmean((frames.z(:)./z2mm)*2);
    irInRoi(k,1) = nanmean(frames.i(:));
    totFrames(k) = frames;
end
figure; subplot(311);plot(laserPtsDec,rtdInRoi);xlabel('Mod ref decimal'); ylabel('RTD'); title('XGA - long')
hold on; subplot(312);plot(laserPtsDec,irInRoi);xlabel('Mod ref decimal'); ylabel('IR');title('XGA - long')     
hold on; subplot(313);plot(laserPtsDec,temps);xlabel('Mod ref decimal'); ylabel('LDD temp');title('XGA - long')     

saveas(gcf,[outputPath '\techSetTo0.fig']);


save([outputPath '\expDataLow.mat']);
hw.stopStream;
hw.cmd('rst');
clear hw
