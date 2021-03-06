function [finishedHeating, calibPassed, results, metrics, metricsWithTheoreticalFix, Invalid_Frames]  = TmptrDataFrame_Calc_int(finishedHeating, regs, eepromRegs, FrameData,height, width, frameBytes, calibParams,maxTime2Wait, output_dir, fprintff, calib_dir, ctKillThr)
% description: initiale set of the DSM scale and offset 
%
% inputs:
%   regs      - register list for calculation (zNorm ,kRaw ,hbaseline
%   ,baseline ,xfov ,yfov ,laserangleH ,laserangleV)
%   FrameData - structure of device state during frame capturing (varity temprature sensor , iBias , vBias etc) 
%   frameBytes - images (in bytes sequence form)
%
% output:
%   result
%       <-1> - error
%        <0> - table not complitted keep calling the function with another samples point.
%        <1> - table ready
calibPassed = 0;
global g_temp_count;
tempSamplePeriod = 60*calibParams.warmUp.warmUpSP;
tempTh = calibParams.warmUp.warmUpTh;
maxTime2WaitSec = maxTime2Wait*60;
runParams.outputFolder = output_dir;
runParams.calibRes = double([height, width]); %TODO: find a more elegant solution to passing calibRes to analyzeFramesOverTemperature
results = struct('nCornersDetected', NaN);
metrics = [];
metricsWithTheoreticalFix = [];
Invalid_Frames = [];

persistent Index
persistent prevTmp
persistent prevTime
persistent lastZFrames
persistent zFramesIndex
persistent diskObject
persistent lastRGBSharpnessTmp

if isempty(Index) || (g_temp_count == 0)
    Index     = 0;
    zFramesIndex = 0;
    prevTmp   = 0;  %hw.getLddTemperature();
    prevTime  = 0;
    lastZFrames = nan([runParams.calibRes,calibParams.warmUp.nFramesForZStd]);
    diskObject = strel('disk',calibParams.roi.diskSz);
    lastRGBSharpnessTmp = 0;
end
% add error checking;

if ~finishedHeating % heating stage
    % frame comprehension
    framesNoAvg = Calibration.aux.convertBytesToFrames(frameBytes, [height, width], [calibParams.gnrl.rgb.res(2), calibParams.gnrl.rgb.res(1)]);
    frame.z = Calibration.aux.average_images(framesNoAvg.z);
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
    if ~(calibParams.gnrl.calibrateShortPreset.enable && FrameData.presetMode == 2) % For z STD we don't want to mix short and long preset values
        lastZFrames(:,:,mod(zFramesIndex:zFramesIndex+nFrames-1,calibParams.warmUp.nFramesForZStd)+1) = zForStd;
        zFramesIndex = zFramesIndex + nFrames;
    end
    % corners tracking
    [FrameData.ptsWithZ, gridSize] = Calibration.thermal.getCornersDataFromThermalFrame(frame, regs, calibParams, true);
    FrameData.ptsWithZ = applyDsmTransformation(FrameData.ptsWithZ, regs, 'inverse'); % avoid using soon-to-be-obsolete DSM values
    results.nCornersDetected = sum(~isnan(FrameData.ptsWithZ(:,1)));
    if all(isnan(FrameData.ptsWithZ(:,1)))
        fprintff('Error: checkerboard not detected in IR image.\n');
        FrameData.ptsWithZ = [];
        calibPassed = -1;
    end
    
    % ROI tracking
    [FrameData.minMaxMemsAngX,FrameData.minMaxMemsAngY] = minMaxDSMAngles(regs,lastZFrames,calibParams,diskObject);
    
    % RX tracking
    FrameData.irStat = Calibration.aux.calcIrStatistics(frame.i, FrameData.ptsWithZ(:,4:5));
    
    % Sharpness tracking
    FrameData.verticalSharpness = Calibration.aux.CBTools.fastGridEdgeSharpIR(frame, gridSize, FrameData.ptsWithZ(:,4:5), struct('target', struct('target', 'checkerboard_Iv2A1'), 'imageRotatedBy180Flag', true));
    
    % Track RGB Vertical and Horizontal Sharpness 
    if isfield(frame,'yuy2')
        if FrameData.temp.ldd - lastRGBSharpnessTmp > calibParams.gnrl.rgb.lddDiffBetweenSharpnessCalc
            [FrameData.verticalSharpnessRGB, FrameData.horizontalSharpnessRGB] = Calibration.aux.CBTools.fastGridEdgeSharpRGB(frame.yuy2,gridSize, FrameData.ptsWithZ(:,6:7));
            lastRGBSharpnessTmp = FrameData.temp.ldd;
        else
            FrameData.verticalSharpnessRGB = nan;
            FrameData.horizontalSharpnessRGB = nan;
        end
    end
    % globals/persistents handling
    framesData = acc_FrameData(FrameData);
    if(Index == 0)
        prevTmp   = FrameData.temp.ldd;
        prevTime  = FrameData.time;
    end
    
    Index = Index+1;
    i = Index;
    
    % heating convergence check
    if ((framesData(i).time - prevTime) >= tempSamplePeriod)
        reachedRequiredTempDiff = ((framesData(i).temp.ldd - prevTmp) < tempTh);
        reachedTimeLimit = (framesData(i).time > maxTime2WaitSec);
        reachedCloseToTKill = (framesData(i).temp.ldd > calibParams.gnrl.lddTKill-1);
        finishedHeating = reachedRequiredTempDiff || ...
            reachedTimeLimit || ...
            reachedCloseToTKill; % will come into effect in next function call
        prevTmp = framesData(i).temp.ldd;
        prevTime = framesData(i).time;
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
    for iFrame = 1:length(framesData)
        framesData(iFrame).ptsWithZ = applyDsmTransformation(framesData(iFrame).ptsWithZ, regs, 'direct'); % recreate corners with up-to-date DSM values
    end
    data.framesData = framesData;
    data.regs = regs;
    data.ctKillThr = ctKillThr;
    
    save(fullfile(output_dir, 'mat_files', 'finalCalcAfterHeating_in.mat'), 'data', 'eepromRegs', 'calibParams', 'fprintff', 'calib_dir', 'output_dir', 'runParams');
    [data, calibPassed, results, metrics, metricsWithTheoreticalFix, Invalid_Frames] = Calibration.thermal.finalCalcAfterHeating(data, eepromRegs, calibParams, fprintff, calib_dir, runParams);
    save(fullfile(output_dir, 'mat_files', 'finalCalcAfterHeating_out.mat'), 'data', 'calibPassed', 'results', 'metrics', 'metricsWithTheoreticalFix', 'Invalid_Frames');
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [minMaxMemsAngX,minMaxMemsAngY] = minMaxDSMAngles(regs,lastZFrames,calibParams,diskObject)
%% Calculates the min and max DSM angles along the center axis of the image (middle row,middle col)
% The purpose is to follow accros the degredation in vertical fov for eye safety concerns, and the horizontal fov for ROI cropping in ACC.
% 
% 1. Target only the largest fully connected component, in case a small
% spherical scale factor causes stripes at the side of image.
% 2. Take the min and max valid pixels for the center row and col and
% return theirDSM values. Use pixels with low STD as "valid pixels"
z2mm = single(regs.GNRL.zNorm);
irrelevantPixels = sum(~isnan(lastZFrames),3) < calibParams.warmUp.nFramesForZStd;
zStd = nanstd(lastZFrames,[],3)/z2mm;
zStd(irrelevantPixels) = nan;
zStd(isnan(zStd)) = inf;
notNoiseIm = zStd<calibParams.roi.zSTDTh;
notNoiseIm = imclose(notNoiseIm,diskObject);

if ~any(notNoiseIm(:))
   % No valid point
    minMaxMemsAngX = [nan,nan];
    minMaxMemsAngY = [nan,nan];
    return;
end

minMaxX = minmax(find(notNoiseIm(round(size(notNoiseIm,1)/2),:)));
minMaxY = minmax(find(notNoiseIm(:,round(size(notNoiseIm,2)/2)))');

xx = (minMaxX-0.5)*4 - double(regs.DIGG.sphericalOffset(1));
yy = minMaxY - double(regs.DIGG.sphericalOffset(2));

xx = xx*2^10;
yy = yy*2^12;

minMaxAngX = xx/double(regs.DIGG.sphericalScale(1));
minMaxAngY = yy/double(regs.DIGG.sphericalScale(2));

minMaxMemsAngX = (minMaxAngX+2047)/regs.EXTL.dsmXscale - regs.EXTL.dsmXoffset;
minMaxMemsAngY = (minMaxAngY+2047)/regs.EXTL.dsmYscale - regs.EXTL.dsmYoffset;
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

function ptsWithZ = applyDsmTransformation(ptsWithZ, regs, type)
    switch type
        case 'direct' % convert from degrees to digital units
            ptsWithZ(:,2) = (ptsWithZ(:,2) + double(regs.EXTL.dsmXoffset)) * double(regs.EXTL.dsmXscale) - 2047;
            ptsWithZ(:,3) = (ptsWithZ(:,3) + double(regs.EXTL.dsmYoffset)) * double(regs.EXTL.dsmYscale) - 2047;
        case 'inverse' % convert from digital units to degrees
            ptsWithZ(:,2) = (ptsWithZ(:,2) + 2047)/double(regs.EXTL.dsmXscale) - double(regs.EXTL.dsmXoffset);
            ptsWithZ(:,3) = (ptsWithZ(:,3) + 2047)/double(regs.EXTL.dsmYscale) - double(regs.EXTL.dsmYoffset);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

