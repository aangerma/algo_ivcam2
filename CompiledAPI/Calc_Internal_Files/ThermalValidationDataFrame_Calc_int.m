function [finishedHeating,calibPassed, results]  = ThermalValidationDataFrame_Calc_int(finishedHeating, unitData, FrameData, sz, frameBytes, calibParams, output_dir, fprintff, algoInternalDir)


calibPassed = 0;
global g_temp_count;
tempSamplePeriod = 60*calibParams.warmUp.warmUpSP;
tempTh = calibParams.warmUp.warmUpTh;
maxTime2WaitSec = calibParams.warmUp.maxWarmUpTime*60;
runParams.outputFolder = output_dir;
runParams.calibRes = double(sz); %TODO: find a more elegant solution to passing calibRes to analyzeFramesOverTemperature
results = struct('nCornersDetected', NaN);

persistent Index
persistent prevTmp
persistent prevTime
persistent prevTmpForBananas
persistent lastZFrames
persistent zFramesIndex
persistent diskObject
persistent regs
persistent luts
persistent rgbData
persistent dacModelFunc

if isempty(Index) || (g_temp_count == 0)
    Index     = 0;
    zFramesIndex = 0;
    prevTmp   = 0;  %hw.getLddTemperature();
    prevTime  = 0;
    prevTmpForBananas = 0;
    lastZFrames = nan([runParams.calibRes,calibParams.warmUp.nFramesForZStd]);
    diskObject = strel('disk',calibParams.roi.diskSz);
    [regs,luts,rgbData] = completeRegState(unitData,algoInternalDir);
end

if isempty(dacModelFunc) && isfield(FrameData, 'dac')
    bytesToDecimal          = @(x) double(typecast(x,'uint16'))/100;
    dacModel.m1             = FrameData.dac.m1;
    dacModel.m2             = FrameData.dac.m2;
    dacModel.calPower       = bytesToDecimal(FrameData.dac.calPower);
    dacModel.calPowerDac0   = bytesToDecimal(FrameData.dac.calPowerDac0);
    dacModel.calTemp        = bytesToDecimal(FrameData.dac.calTemp);
    dacModel.calDac         = double(FrameData.dac.calDac);
    dacModel.modRefPct      = double(FrameData.dac.modRefPctBytes);
    dacModelFunc            = @(t) round(((dacModel.calPower-dacModel.calPowerDac0)*dacModel.modRefPct/100 - dacModel.m2*(t-dacModel.calTemp)) ./ ((dacModel.calPower-dacModel.calPowerDac0)/dacModel.calDac+dacModel.m1*(t-dacModel.calTemp)));
end

% add error checking;

if ~finishedHeating % heating stage
    % frame comprehension
    framesNoAvg = Calibration.aux.convertBytesToFrames(frameBytes, sz, [calibParams.gnrl.rgb.res(2), calibParams.gnrl.rgb.res(1)]);
    frame.z = Calibration.aux.average_images(framesNoAvg.z);
    frame.c = Calibration.aux.average_images(framesNoAvg.c);
    frame.i = Calibration.aux.average_images(framesNoAvg.i);
    if isfield(framesNoAvg,'yuy2')
        frame.yuy2 = Calibration.aux.average_images(framesNoAvg.yuy2);
    end
    
    % bananas tracking
    nFrames = size(framesNoAvg.z,3);
    binLargest = maxAreaMask(frame.i>0); % In case of small spherical scale factor that causes weird striped to appear
    zForStd = zeros(size(framesNoAvg.z));
    zForStd(repmat(binLargest,1,1,nFrames)) = framesNoAvg.z(repmat(binLargest,1,1,nFrames));
    zForStd(zForStd == 0) = nan;
    lastZFrames(:,:,mod(zFramesIndex:zFramesIndex+nFrames-1,calibParams.warmUp.nFramesForZStd)+1) = zForStd;

    % DAC model tracking
    if isfield(FrameData, 'dac')
        FrameData.dac.predicted = uint8(dacModelFunc(FrameData.temp.ldd));
    end
    
    % corners tracking
    [FrameData.ptsWithZ, gridSize] = Calibration.thermal.getCornersDataFromThermalFrame(frame, regs, calibParams, false);
    FrameData.confPts = interp2(single(frame.c),FrameData.ptsWithZ(:,4),FrameData.ptsWithZ(:,5));
    results.nCornersDetected = sum(~isnan(FrameData.ptsWithZ(:,1)));
    
    lddDiffFromLastBananasIsGreat = (FrameData.temp.ldd - prevTmpForBananas) > calibParams.validation.bananas.lddInterVals;
    if lddDiffFromLastBananasIsGreat
        prevTmpForBananas = FrameData.temp.ldd;
        captureBananaFigure(frame,calibParams,runParams,prevTmpForBananas,lastZFrames,diskObject);
    end

    if all(isnan(FrameData.ptsWithZ(:,1)))
        fprintff('Error: checkerboard not detected in IR image.\n');
        FrameData.ptsWithZ = [];
        FrameData.confPts = [];
        FrameData.irStat = [];
        FrameData.cStat = [];
        FrameData.verticalSharpness = [];
        calibPassed = -1;
    else
        % RX tracking
        FrameData.irStat = Calibration.aux.calcIrStatistics(frame.i, FrameData.ptsWithZ(:,4:5));
        FrameData.cStat = Calibration.aux.calcConfStatistics(frame.c, FrameData.ptsWithZ(:,4:5));
        % Sharpness tracking
        FrameData.verticalSharpness = Calibration.aux.CBTools.fastGridEdgeSharpIR(frame, gridSize, FrameData.ptsWithZ(:,4:5), struct('target', struct('target', 'checkerboard_Iv2A1'), 'imageRotatedBy180Flag', true));
    end
    acc_FrameData(FrameData);
    if(Index == 0)
        prevTmp   = FrameData.temp.ldd;
        prevTime  = FrameData.time;
    end
    zFramesIndex = zFramesIndex + nFrames;
    Index = Index+1;
    
    % heating convergence check
    if ((FrameData.time - prevTime) >= tempSamplePeriod)
        reachedRequiredTempDiff = ((FrameData.temp.ldd - prevTmp) < tempTh);
        reachedTimeLimit = (FrameData.time > maxTime2WaitSec);
        reachedCloseToTKill = (FrameData.temp.ldd > calibParams.gnrl.lddTKill-1);
        finishedHeating = reachedRequiredTempDiff || ...
            reachedTimeLimit || ...
            reachedCloseToTKill; % will come into effect in next function call
        prevTmp = FrameData.temp.ldd;
        prevTime = FrameData.time;
        fprintff(', %2.2f',prevTmp);
    end
    if (finishedHeating)
        if reachedRequiredTempDiff
            reason = 'Stable temperature';
        elseif reachedTimeLimit
            reason = 'Passed time limit';
        elseif reachedCloseToTKill
            reason = 'Reached close to TKILL';
        end
        fprintff('Finished heating reason: %s\n',reason);
    end
    
    
else % steady-state stage
    framesData = acc_FrameData([]); % simply reconstruct entire struct array
    data.framesData = framesData;
    data.regs = regs;
    data.luts = luts;
    data.rgbData = rgbData;
    data.unitData = unitData;
    
    S.data = data;
    S.calibParams = calibParams;
    S.fprintff = @fprintf;
    S.algoInternalDir = algoInternalDir;
    S.output_dir = output_dir;
    S.runParams = runParams;
    save(fullfile(output_dir, 'mat_files', 'validationCalcAfterHeating_in.mat'), '-struct', 'S');
    [data, results] = Calibration.thermal.validationCalcAfterHeating(data,calibParams, fprintff, algoInternalDir, runParams);
    save(fullfile(output_dir, 'mat_files', 'validationCalcAfterHeating_out.mat'), 'data', 'results');
end
    
% update ptsWithZ per frame
% update persistent table 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function a = acc_FrameData(a)
    global acc;
    acc = [acc; a] ;
    a = acc;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [bananasExist,validFillRatePrc] = captureBananaFigure(frame,calibParams,runParams,lddTemp,lastZFrames,diskObject)
    z = lastZFrames;
    z(z==0) = nan;%randi(9000,size(zCopy(z==0)));
    stdZ = nanstd(z,[],3);
    stdZ(isnan(stdZ)) = inf;

    notNoiseIm = stdZ<calibParams.validation.bananas.zSTDTh & sum(isnan(z),3) == 0;
    notNoiseImClosed = imclose(notNoiseIm,diskObject);
    bananasExist = ~all(notNoiseImClosed(:));
    validFillRatePrc = mean(notNoiseImClosed(:))*100;
    
    if ~isempty(runParams) && isfield(runParams, 'outputFolder')
        ff = Calibration.aux.invisibleFigure;
        subplot(311);
        imagesc(frame.i);
        title(sprintf('IR Image At Ldd=%2.2fdeg',lddTemp));
        subplot(312);
        imagesc(stdZ,[0,10]);
        title('Z Std Image');
        subplot(313);
        imagesc(notNoiseImClosed);
        title('Binary Valid Pixels');
        Calibration.aux.saveFigureAsImage(ff,runParams,'Heating','Bananas',1);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [binLargest] = maxAreaMask(binaryIm)
CC = bwconncomp(binaryIm);
numPixels = cellfun(@numel,CC.PixelIdxList);
[~,idx] = max(numPixels);
binLargest = zeros(size(binaryIm),'logical');
binLargest(CC.PixelIdxList{idx}) = 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [regs,luts,rgbData] = completeRegState(unitData,algoInternalDir)

% It is cal
% kWorld = unitData.regs.FRMW.kWorld;
% unitData.regs.FRMW = rmfield(unitData.regs.FRMW,'kWorld');

eepromRegs = extractEepromRegs(unitData.eepromBin, algoInternalDir);

% fw = Pipe.loadFirmware(algoInternalDir,'tablesFolder',algoInternalDir);
% fw.setRegs(eepromRegs,'');
% fw.setRegs(unitData.regs,'');
% [regs,luts] = fw.get();
initFolder = algoInternalDir;
fw = Pipe.loadFirmware(initFolder, 'tablesFolder', initFolder);
regs = fw.mergeRegs(eepromRegs,unitData.regs);
luts.DIGG.undistModel = typecast(unitData.diggUndistBytes(:),'int32');
regs.FRMW.mirrorMovmentMode = 1;
regs.MTLB.fastApprox = ones(1,8,'logical');
regs.FRMW.kWorld = unitData.kWorld;
regs.FRMW.kRaw = regs.FRMW.kWorld;
regs.FRMW.kRaw(7) = single(regs.GNRL.imgHsize) - 1 - regs.FRMW.kRaw(7);
regs.FRMW.kRaw(8) = single(regs.GNRL.imgVsize) - 1 - regs.FRMW.kRaw(8);

[rgbData] = parseRgbData(unitData);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [rgbData] = parseRgbData(unitData)
rgbData = Calibration.tables.convertBinTableToCalibData(unitData.rgbThermalData, 'RGB_Thermal_Info_CalibInfo');
tempVar = char(join(string(flip(dec2hex(unitData.rgbCalibData(121:125))))));
tempVar = tempVar(~isspace(tempVar));
rgbData.rgbCalTemp = hex2single(tempVar);
end