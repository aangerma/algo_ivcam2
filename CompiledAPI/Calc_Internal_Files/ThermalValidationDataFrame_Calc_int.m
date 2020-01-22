function [finishedHeating,calibPassed, results]  = ThermalValidationDataFrame_Calc_int(finishedHeating,unitData,FrameData, sz, frameBytes, calibParams, output_dir, fprintff, algoInternalDir)


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


if isempty(Index) || (g_temp_count == 0)
    Index     = 0;
    zFramesIndex = 0;
    prevTmp   = 0;  %hw.getLddTemperature();
    prevTime  = 0;
    prevTmpForBananas = 0;
    lastZFrames = nan([runParams.calibRes,calibParams.warmUp.nFramesForZStd]);
    diskObject = strel('disk',calibParams.roi.diskSz);
    if isfield(calibParams.gnrl,'rgb') && isfield(calibParams.gnrl.rgb,'nBinsThermal')
        nBinsRgb = calibParams.gnrl.rgb.nBinsThermal;
    else
        nBinsRgb = 29;
    end
    [regs,luts,rgbData] = completeRegState(unitData,algoInternalDir,nBinsRgb);
    
    
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
    
    % corners tracking
    [FrameData.ptsWithZ, gridSize] = cornersData(frame,regs,calibParams);
    FrameData.confPts = interp2(single(frame.c),FrameData.ptsWithZ(:,4),FrameData.ptsWithZ(:,5));
    results.nCornersDetected = sum(~isnan(FrameData.ptsWithZ(:,1)));
    
    lddDiffFromLastBananasIsGreat = (FrameData.temp.ldd - prevTmpForBananas) > calibParams.validation.bananas.lddInterVals;
    if lddDiffFromLastBananasIsGreat
        prevTmpForBananas = FrameData.temp.ldd;
        captureBananaFigure(frame,calibParams,runParams,prevTmpForBananas,lastZFrames,diskObject);
    end
    % globals/persistents handling
    
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

function [ptsWithZ, gridSize] = cornersData(frame,regs,calibParams)
    sz = size(frame.i);
    pixelCropWidth = sz.*calibParams.gnrl.cropFactors;
    frame.i([1:pixelCropWidth(1),round(sz(1)-pixelCropWidth(1)):sz(1)],:) = 0;
    frame.i(:,[1:pixelCropWidth(2),round(sz(2)-pixelCropWidth(2)):sz(2)]) = 0;
    
    if isempty(calibParams.gnrl.cbGridSz)
        [pts,colors] = Calibration.aux.CBTools.findCheckerboardFullMatrix(frame.i, 1, [], [], calibParams.gnrl.nonRectangleFlag);
%         if all(isnan(pts(:)))
%             Calibration.aux.CBTools.interpretFailedCBDetection(frame.i, 'Heating IR image');
%         end
        pts = reshape(pts,[],2);
        gridSize = [size(pts,1),size(pts,2),1];
        if isfield(frame,'yuy2')
            [ptsColor,~] = Calibration.aux.CBTools.findCheckerboardFullMatrix(frame.yuy2, 0, [], [], calibParams.gnrl.rgb.nonRectangleFlag);
%             if all(isnan(ptsColor(:)))
%                 Calibration.aux.CBTools.interpretFailedCBDetection(frame.yuy2, 'Heating RGB image');
%             end
        end
    else
        colors = [];
        [pts,gridSize] = Validation.aux.findCheckerboard(frame.i,calibParams.gnrl.cbGridSz); % p - 3 checkerboard points. bsz - checkerboard dimensions.
        if ~isequal(gridSize, calibParams.gnrl.cbGridSz)
            warning('Checkerboard not detected in IR image. All of the target must be included in the image');
            ptsWithZ = [];
            return;
        end
        if isfield(frame,'yuy2')
            [ptsColor,gridSizeRgb] = Validation.aux.findCheckerboard(frame.yuy2,calibParams.gnrl.cbGridSz); % p - 3 checkerboard points. bsz - checkerboard dimensions.
            if ~isequal(gridSizeRgb, calibParams.gnrl.cbGridSz)
                warning('Checkerboard not detected in color image. All of the target must be included in the image');
                ptsWithZ = [];
                return;
            end
        end
    end
    
    
    
    
%     if isempty(colors)
%         rpt = Calibration.aux.samplePointsRtd(frame.z,pts,regs);
%     else
%         rpt = Calibration.aux.samplePointsRtd(frame.z,reshape(pts,20,28,2),regs,0,colors,calibParams.gnrl.sampleRTDFromWhiteCheckers);
%     end
%     rpt(:,1) = rpt(:,1) - regs.DEST.txFRQpd(1);
%     ptsWithZ = [rpt,reshape(pts,[],2)]; % without XYZ which is not calibrated well at this stage
%     ptsWithZ(isnan(ptsWithZ(:,1)),:) = nan;
    zIm = single(frame.z)/single(regs.GNRL.zNorm);
    if calibParams.gnrl.sampleRTDFromWhiteCheckers && isempty(calibParams.gnrl.cbGridSz)
        [zPts,~,~,pts,~] = Calibration.aux.CBTools.valuesFromWhitesNonSq(zIm,reshape(pts,20,28,2),colors,1/8);
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
    angx = rtd*0;% All nan will cause the analysis to fail
    angy = rtd*0;% All nan will cause the analysis to fail
    ptsWithZ = [rtd,angx,angy,pts,verts];
    ptsWithZ(isnan(ptsWithZ(:,1)),:) = nan;
    if isfield(frame,'yuy2')
        ptsWithZ = [ptsWithZ,reshape(ptsColor,[],2)];
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [regs,luts,rgbData] = completeRegState(unitData,algoInternalDir,nBinsRgb)

% It is cal
% kWorld = unitData.regs.FRMW.kWorld;
% unitData.regs.FRMW = rmfield(unitData.regs.FRMW,'kWorld');

eepromRegs = extractEepromRegs(unitData.eepromBin, algoInternalDir);

% fw = Pipe.loadFirmware(algoInternalDir,'tablesFolder',algoInternalDir);
% fw.setRegs(eepromRegs,'');
% fw.setRegs(unitData.regs,'');
% [regs,luts] = fw.get();
fw = Firmware;
regs = fw.mergeRegs(eepromRegs,unitData.regs);
luts.DIGG.undistModel = typecast(unitData.diggUndistBytes(:),'int32');
regs.FRMW.mirrorMovmentMode = 1;
regs.MTLB.fastApprox = ones(1,8,'logical');
regs.FRMW.kWorld = unitData.kWorld;
regs.FRMW.kRaw = regs.FRMW.kWorld;
regs.FRMW.kRaw(7) = single(regs.GNRL.imgHsize) - 1 - regs.FRMW.kRaw(7);
regs.FRMW.kRaw(8) = single(regs.GNRL.imgVsize) - 1 - regs.FRMW.kRaw(8);

[rgbData] = parseRgbData(unitData,nBinsRgb);
end


function [rgbData] = parseRgbData(unitData,nBinsRgb)
rgbData = Calibration.aux.convertRgbThermalBytesToData(unitData.rgbThermalData,nBinsRgb);
tempVar = char(join(string(flip(dec2hex(unitData.rgbCalibData(121:125))))));
tempVar = tempVar(~isspace(tempVar));
rgbData.rgbCalTemp = hex2single(tempVar);
end