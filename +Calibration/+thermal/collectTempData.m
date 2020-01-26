function [ framesData, info, validFillRatePrc ] = collectTempData(hw,regs,calibParams,runParams,fprintff,maxTime2Wait,app,inValidationStage)

tempSamplePeriod = 60*calibParams.warmUp.warmUpSP;
tempTh = calibParams.warmUp.warmUpTh;
timeBetweenFrames = calibParams.warmUp.timeBetweenFrames;
maxTime2WaitSec = maxTime2Wait*60;

pN = 1000;
tempsForPlot = nan(1,pN);
timesForPlot = nan(1,pN);
plotDataI = 1;


isXGA = all(runParams.calibRes==[768,1024]);
if isXGA
    hw.cmd('ENABLE_XGA_UPSCALE 1')
end
if calibParams.gnrl.rgb.doStream && inValidationStage
    runParams.rgb = 1;
    runParams.rgbRes = calibParams.gnrl.rgb.res;
end
if isfield(calibParams.gnrl, 'presetNum')
    hw.setPresetControlState(calibParams.gnrl.presetNum);
end
Calibration.aux.startHwStream(hw,runParams);
if calibParams.gnrl.sphericalMode
    hw.setReg('DIGGsphericalEn',1);
    hw.cmd(sprintf('mwd a0020c00 a0020c04 %x // DIGGsphericalScale',typecast(regs.DIGG.sphericalScale,'uint32')))
%     hw.setReg('DIGGsphericalScale',dec2hex(typecast(regs.DIGG.sphericalScale,'uint32')));
    hw.setReg('DESTdepthAsRange',1);
    hw.setReg('DESTbaseline$',single(0));
    hw.setReg('DESTbaseline2',single(0));
end
hw.cmd('mwd a00e1890 a00e1894 00000001 // JFILinvBypass');
hw.cmd('mwd a00e18b8 a00e18bc ffff0000 // JFILinvMinMax');
hw.cmd('mwd a0020834 a0020838 ffffffff // DCORcoarseMasking_002'); 
confScriptFldr = fullfile(runParams.outputFolder,'AlgoInternal','confAsDC.txt');
hw.runScript(confScriptFldr);
hw.shadowUpdate;

prevTmp = hw.getLddTemperature();
prevTmpForBananas = prevTmp;
prevTime = 0;
tempsForPlot(plotDataI) = prevTmp;
timesForPlot(plotDataI) = prevTime/60;
plotDataI = mod(plotDataI,pN)+1;

startTime = tic;
%% Collect data until temperature doesn't raise any more
finishedHeating = 0; % A unit finished heating when LDD temperature doesn't raise by more than 0.2 degrees between 1 minute and the next
manualCaptures = isfield(runParams,'manualCaptures') && runParams.manualCaptures;
if manualCaptures
    app.stopWarmUpButton.Visible = 'on';
    app.stopWarmUpButton.Enable = 'on'; 
end

fprintff('[-] Starting heating stage (waiting for diff<%1.1f over %1.1f minutes) ...\n',tempTh,calibParams.warmUp.warmUpSP);
fprintff('Ldd temperatures: %2.2f',prevTmp);
[bananasExist,validFillRatePrc(1)] = captureBananaFigure(hw,calibParams,runParams,prevTmpForBananas);
if bananasExist
    fprintff('Detected invalid pixels in first frames (possible bananas). Valid fill rate: %3.6g \n',validFillRatePrc(1));
else
    fprintff('All are valid pixels in first frames (no bananas). Valid fill rate: %3.6g \n',validFillRatePrc(1));
end



i = 0;
tempFig = figure(190789);
plot(timesForPlot,tempsForPlot); xlabel('time(minutes)');ylabel('ldd temp(degrees)');title(sprintf('Heating Progress - %2.2fdeg',tempsForPlot(plotDataI)));

while ~finishedHeating
    i = i + 1;
    [tmpData,frame] = getFrameData(hw,regs,calibParams);
    saveFrames(frame,calibParams,runParams,i);
    if isempty(tmpData.ptsWithZ)
        calibParams.gnrl.saveFrames = 1;
        saveFrames(frame,calibParams,runParams,i);
        error('Checkerboard detection failure -> saving frame for debug');
    end
    if i == 1
        firstFrame = frame;
    end
    tmpData.time = toc(startTime);
    framesData(i) = tmpData;
    
    if tempFig.isvalid
        tempsForPlot(plotDataI) = framesData(i).temp.ldd;
        timesForPlot(plotDataI) = framesData(i).time/60;
        figure(190789);plot(timesForPlot([plotDataI+1:pN,1:plotDataI]),tempsForPlot([plotDataI+1:pN,1:plotDataI])); xlabel('time(minutes)');ylabel('ldd temp(degrees)');title(sprintf('Heating Progress - %2.2fdeg',tempsForPlot(plotDataI)));drawnow;
        plotDataI = mod(plotDataI,pN)+1;
    end
    if ((framesData(i).time - prevTime) >= tempSamplePeriod)  || (manualCaptures && Calibration.aux.globalSkip(0)) 
        manualSkip = (manualCaptures && Calibration.aux.globalSkip(0));
        reachedRequiredTempDiff = ((framesData(i).temp.ldd - prevTmp) < tempTh);
        reachedTimeLimit = (framesData(i).time > maxTime2WaitSec);
        reachedCloseToTKill = (framesData(i).temp.ldd > calibParams.gnrl.lddTKill-1);
        raisedFarAboveCalibTemp = (framesData(i).temp.ldd > regs.FRMW.dfzCalTmp+calibParams.warmUp.teminationTempdiffFromCalibTemp);
        
        finishedHeating = manualSkip  || ...
                          reachedRequiredTempDiff || ...
                          reachedTimeLimit || ...
                          reachedCloseToTKill || ...
                          raisedFarAboveCalibTemp;
        
        
        prevTmp = framesData(i).temp.ldd;
        prevTime = framesData(i).time;
        fprintff(', %2.2f',prevTmp);
        
    end
    lddDiffFromLastBananasIsGreat = (framesData(i).temp.ldd - prevTmpForBananas) > calibParams.bananas.lddInterVals;
    if lddDiffFromLastBananasIsGreat
        prevTmpForBananas = framesData(i).temp.ldd;
        captureBananaFigure(hw,calibParams,runParams,prevTmpForBananas);
    end
    pause(timeBetweenFrames);
    
    if i == 4
        sceneFig = figure(190790);
        imshow(rot90(hw.getFrame().i,2));
        title('Scene Image');
    end
end
lastFrame = frame;

if i >=4 && sceneFig.isvalid
    close(sceneFig);
end
if tempFig.isvalid
    close(tempFig);
end

[bananasExist,validFillRatePrc(2)] = captureBananaFigure(hw,calibParams,runParams,prevTmp);
if bananasExist
    fprintff('Detected invalid pixels in last frames (possible bananas). Valid fill rate: %3.6g \n',validFillRatePrc(2));
else
    fprintff('All are valid pixels in last frames (no bananas). Valid fill rate: %3.6g \n',validFillRatePrc(2));
end

hw.stopStream;
fprintff('Done\n');

if manualSkip
    reason = 'Manual skip';
elseif reachedRequiredTempDiff
    reason = 'Stable temperature';
elseif reachedTimeLimit
    reason = 'Passed time limit';
elseif reachedCloseToTKill
    reason = 'Reached close to TKILL';
elseif raisedFarAboveCalibTemp
    reason = 'Raised far above calib temperature';
end
fprintff('Finished heating reason: %s\n',reason);


heatTimeVec = [framesData.time];
tempVec = [framesData.temp];
LddTempVec = [tempVec.ldd];

if ~isempty(runParams) && isfield(runParams, 'outputFolder')
    ff = Calibration.aux.invisibleFigure;
    plot(heatTimeVec,LddTempVec)
    hold on    
    plot(heatTimeVec,[tempVec.ma])
    plot(heatTimeVec,[tempVec.mc])
    plot(heatTimeVec,[tempVec.apdTmptr])
    legend({'ldd';'ma';'mc';'apd'});
    title('Heating Stage'); grid on;xlabel('sec');ylabel('Temperatures [degrees]');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('TemperatureReadings'),1);
    
    if calibParams.gnrl.rgb.doStream && inValidationStage
        ff = Calibration.aux.invisibleFigure;
        subplot(321)
        imagesc(firstFrame.color);
        title(['Minimum temperature RGB image. Ldd = ' num2str(framesData(1).temp.ldd)]);
        subplot(322)
        imagesc(lastFrame.color);
        title(['Maximum temperature RGB image. Ldd = ' num2str(framesData(end).temp.ldd)]);
        subplot(323)
        imagesc(rot90(firstFrame.i,2));
        title(['Minimum temperature IR image. Ldd = ' num2str(framesData(1).temp.ldd)]);
        subplot(324)
        imagesc(rot90(lastFrame.i,2));
        title(['Maximum temperature IR image. Ldd = ' num2str(framesData(end).temp.ldd)]);
        subplot(325)
        imagesc(rot90(firstFrame.z,2));
        title(['Minimum temperature depth image. Ldd = ' num2str(framesData(1).temp.ldd)]);
        subplot(326)
        imagesc(rot90(lastFrame.z,2));
        title(['Maximum temperature depth image. Ldd = ' num2str(framesData(end).temp.ldd)]);
        Calibration.aux.saveFigureAsImage(ff,runParams,'imThermalCompare',sprintf('depthNrgb'),1);
    end
end
info.duration = heatTimeVec(end);
info.startTemp = LddTempVec(1);
info.endTemp = LddTempVec(end);


if manualCaptures
    app.stopWarmUpButton.Visible = 'off';
    app.stopWarmUpButton.Enable = 'off'; 
    Calibration.aux.globalSkip(1,0);
end




end
function saveFrames(frame,calibParams,runParams,idx)
if calibParams.gnrl.saveFrames
    if isfield(frame,'c')
        frame = rmfield(frame,'c');
    end
    if isfield(frame,'color')
        frame = rmfield(frame,'color');
    end
    framesDir = fullfile(runParams.outputFolder,'frames');
    mkdirSafe(framesDir);
    framePath = fullfile(framesDir,sprintf('frame_%02d',idx));
    save(framePath,'frame');
end
if calibParams.gnrl.saveRGB
    if isfield(frame,'c')
        frame = rmfield(frame,'c');
    end
    if isfield(frame,'i')
        frame = rmfield(frame,'i');
    end
    if isfield(frame,'z')
        frame = rmfield(frame,'z');
    end
    framesDir = fullfile(runParams.outputFolder,'framesRGB');
    mkdirSafe(framesDir);
    framePath = fullfile(framesDir,sprintf('frame_%02d',idx));
    save(framePath,'frame');
end

end
function [ptsWithZ, gridSize] = cornersData(frame,regs,calibParams)
if isempty(calibParams.gnrl.cbGridSz)
   
    CB = CBTools.Checkerboard (frame.i,'targetType', 'checkerboard_Iv2A1','imageRotatedBy180',true);  
    gridSize = CB.getGridSize;
    pts = CB.getGridPointsList;
    colors = CB.getColorMap;
    if calibParams.gnrl.rgb.doStream
        CB = CBTools.Checkerboard (frame.color,'targetType', 'checkerboard_Iv2A1');  
        ptsColor = CB.getGridPointsList;
    end
else
    CB = CBTools.Checkerboard (frame.i,'expectedGridSize',calibParams.gnrl.cbGridSz); 
    gridSize = CB.getGridSize;
    pts = CB.getGridPointsList;
    
    if ~isequal(gridSize, calibParams.gnrl.cbGridSz)
        ptsWithZ = [];
        return;
    end
     if calibParams.gnrl.rgb.doStream
         CB = CBTools.Checkerboard (frame.color,'expectedGridSize',calibParams.gnrl.cbGridSz);
         gridSizeRgb = CB.getGridSize;
         pts = CB.getGridPointsList;
        if ~isequal(gridSizeRgb, calibParams.gnrl.cbGridSz)
            ptsWithZ = [];
            return;
        end
    end
end
if ~regs.DIGG.sphericalEn
    zIm = single(frame.z)/single(regs.GNRL.zNorm);
    if calibParams.gnrl.sampleRTDFromWhiteCheckers && isempty(calibParams.gnrl.cbGridSz)
        [zPts,~,~,pts,~] = CBTools.valuesFromWhitesNonSq(zIm,reshape(pts,20,28,2),colors,1/8);
        pts = reshape(pts,[],2);
    else
        zPts = interp2(zIm,pts(:,1),pts(:,2));
    end
    matKi=(regs.FRMW.kRaw)^-1;
    
    u = pts(:,1)-1;
    v = pts(:,2)-1;
    
    tt=zPts'.*[u';v';ones(1,numel(v))];
    verts=(matKi*tt)';
    
    %% Get r,angx,angy
    if regs.DEST.hbaseline
        rxLocation = [regs.DEST.baseline,0,0];
    else
        rxLocation = [0,regs.DEST.baseline,0];
    end
    rtd = sqrt(sum(verts.^2,2)) + sqrt(sum((verts - rxLocation).^2,2));
    [angx,angy] = Calibration.aux.vec2ang(normr(verts),regs);
    [angx,angy] = Calibration.Undist.inversePolyUndistAndPitchFix(angx,angy,regs);
    ptsWithZ = [rtd,angx,angy,pts,verts];
    ptsWithZ(isnan(ptsWithZ(:,1)),:) = nan;
    if calibParams.gnrl.rgb.doStream
        ptsWithZ = [ptsWithZ,ptsColor];
    end
%     v = ptsWithZ(:,6:8);
%     if size(v,1) == 20*28
%         v = reshape(v,20,28,3);
%         rows = find(any(~isnan(v(:,:,1)),2));
%         cols = find(any(~isnan(v(:,:,1)),1));
%         grd = [numel(rows),numel(cols)];
%         v = reshape(v(rows,cols,:),[],3);
%     else
%         grd = [9,13];
%     end
%     [eGeom, ~, ~] = Validation.aux.gridError(v, grd, 30);
%     fprintf('eGeom - %2.2f\n',eGeom);
else
    rpt = Calibration.aux.samplePointsRtd(frame.z,pts,regs);
    rpt(:,1) = rpt(:,1) - regs.DEST.txFRQpd(1);
    [angxPostUndist,angyPostUndist] = Calibration.Undist.applyPolyUndistAndPitchFix(rpt(:,2),rpt(:,3),regs);
    vUnit = Calibration.aux.ang2vec(angxPostUndist,angyPostUndist,regs)';
    %vUnit = reshape(vUnit',size(d.rpt));
    %vUnit(:,:,1) = vUnit(:,:,1);
    % Update scale to take margins into acount.
    if regs.DEST.hbaseline
        sing = vUnit(:,1);
    else
        sing = vUnit(:,2);
    end
    rtd_=rpt(:,1);
    r = (0.5*(rtd_.^2 - 100))./(rtd_ - 10.*sing);
    v = double(vUnit.*r);
    ptsWithZ = [rpt,reshape(pts,[],2),v];
    ptsWithZ(isnan(ptsWithZ(:,1)),:) = nan;
    if calibParams.gnrl.rgb.doStream
        ptsWithZ = [ptsWithZ,ptsColor];
    end
end
end

function [frameData,frame] = getFrameData(hw,regs,calibParams)
    frame = hw.getFrame();
    if calibParams.gnrl.rgb.doStream
        rgbFrame  = hw.getColorFrame();
        frame.color = rgbFrame.color;
    end
    [frameData.temp.ldd,frameData.temp.mc,frameData.temp.ma,frameData.temp.apdTmptr] = hw.getLddTemperature;
    frameData.temp.humidity = hw.getHumidityTemperature;
%     frameData.pzrShifts = hw.pzrShifts;
    for j = 1:3
        [frameData.iBias(j), frameData.vBias(j)] = hw.pzrAvPowerGet(j,calibParams.gnrl.pzrMeas.nVals2avg,calibParams.gnrl.pzrMeas.sampIntervalMsec);
    end
    try
        [frameData.ptsWithZ, gridSize] = cornersData(frame,regs,calibParams);
        frameData.confPts = interp2(single(frame.c),frameData.ptsWithZ(:,4),frameData.ptsWithZ(:,5));
        frameData.flyback = hw.cmd('APD_FLYBACK_VALUES_GET');
        frameData.maVoltage = hw.getMaVoltagee();
        % RX tracking
        frameData.irStat = Calibration.aux.calcIrStatistics(frame.i, frameData.ptsWithZ(:,4:5));
        frameData.cStat = Calibration.aux.calcConfStatistics(frame.c, frameData.ptsWithZ(:,4:5));
        %     params.camera.zMaxSubMM = 4;
        %     params.camera.K = regs.FRMW.kRaw;
        %     params.target.squareSize = 30;
        %     params.expectedGridSize = [9,13];
        %     [frameData.eGeom, allRes,dbg] = Validation.metrics.gridInterDistance(frame, params);
        frameData.verticalSharpness = Calibration.aux.CBTools.fastGridEdgeSharpIR(frame, gridSize, frameData.ptsWithZ(:,4:5), struct('target', struct('target', 'checkerboard_Iv2A1'), 'imageRotatedBy180Flag', true));
    catch er
        frameData.ptsWithZ = [];
    end
end


function [bananasExist,validFillRatePrc] = hasBananas(frames,calibParams,runParams,lddTemp,figtitle)
    nf = numel(frames);
    z = single(cat(3,frames.z));
    z(z==0) = nan;%randi(9000,size(zCopy(z==0)));
    stdZ = nanstd(z,[],3);
    stdZ(isnan(stdZ)) = inf;

    notNoiseIm = stdZ<calibParams.bananas.zSTDTh & sum(isnan(z),3) == 0;
    se = strel('disk',calibParams.bananas.diskSz);
    notNoiseImClosed = imclose(notNoiseIm,se);
    bananasExist = ~all(notNoiseImClosed(:));
    validFillRatePrc = mean(notNoiseImClosed(:))*100;
    
    if ~isempty(runParams) && isfield(runParams, 'outputFolder')
        ff = Calibration.aux.invisibleFigure;
        subplot(311);
        imagesc(frames(1).i);
        title(sprintf('IR Image At Ldd=%2.2fdeg',lddTemp));
        subplot(312);
        imagesc(stdZ,[0,10]);
        title('Z Std Image');
        subplot(313);
        imagesc(notNoiseImClosed);
        title('Binary Valid Pixels');
        Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',figtitle,1);
    end
end
function [bananasExist,validFillRatePrc] = captureBananaFigure(hw,calibParams,runParams,lddTmp)

nf = 30;
hw.getFrame(nf);
frames = hw.getFrame(nf,0);
[bananasExist,validFillRatePrc] = hasBananas(frames,calibParams,runParams,lddTmp,sprintf('Banana_Frame'));
end