function [finishedHeating, calibPassed, results, metrics, Invalid_Frames]  = TmptrDataFrame_Calc(finishedHeating, regs, eepromRegs, eepromBin, FrameData, sz ,frameBytes, calibParams, maxTime2Wait)

%function [result, data ,table]  = TemDataFrame_Calc(regs, FrameData, sz ,InputPath,calibParams, maxTime2Wait)
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
%   tableResults
%   metrics - validation metrics relvent only on last phase when table
%   ready
%   invalid_Frames - number of invalid frames relvent only on last phase when table
%   ready
%
    global g_output_dir g_calib_dir g_save_input_flag  g_save_output_flag  g_fprintff g_temp_count g_LogFn; % g_regs g_luts;
    fprintff = g_fprintff;
    
    % setting default global value in case not initial in the init function;
    if isempty(g_temp_count)
        g_temp_count = 0;
    end
    if isempty(g_save_input_flag)
        g_save_input_flag = 0;
    end
    if isempty(g_save_output_flag)
        g_save_output_flag = 0;
    end
    
    func_name = dbstack;
    func_name = func_name(1).name;

    if(isempty(g_output_dir))
        output_dir = fullfile(ivcam2tempdir, func_name);
        mkdirSafe(output_dir);
        g_output_dir = output_dir;
    else
        output_dir = g_output_dir;
    end
    %% log output
    if(isempty(g_fprintff)) %% HVM log file
        if(isempty(g_LogFn))
            fn = fullfile(output_dir,'algo2_log.txt');
        else
            fn = g_LogFn;
        end
        mkdirSafe(output_dir);
        fid = fopen(fn,'a');
        fprintff = @(varargin) fprintf(fid,varargin{:});
    else % algo_cal app_windows
        fprintff = g_fprintff; 
    end

    % save Input
    if g_save_input_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' ,[func_name sprintf('_in%d.mat',g_temp_count)]);
        save(fn,'finishedHeating','regs', 'eepromRegs','eepromBin', 'FrameData', 'sz' ,'frameBytes','calibParams', 'maxTime2Wait' );
    end
    height = sz(1);
    width  = sz(2);
    initFolder = g_calib_dir;
    fw = Pipe.loadFirmware(initFolder,'tablesFolder',initFolder);
    if(isempty(eepromRegs) || ~isstruct(eepromRegs))
        EPROMstructure  = load(fullfile(g_calib_dir,'eepromStructure.mat'));
        EPROMstructure  = EPROMstructure.updatedEpromTable;
        eepromBin       = uint8(eepromBin);
        eepromRegs      = fw.readAlgoEpromData(eepromBin(17:end),EPROMstructure);
        [regs]          = struct_merge(eepromRegs, regs);
    end
    origFinishedHeating = finishedHeating;
    [finishedHeating, calibPassed, results, metrics, Invalid_Frames] = TmptrDataFrame_Calc_int(finishedHeating, regs, eepromRegs, FrameData, height , width, frameBytes, calibParams, maxTime2Wait, output_dir, fprintff, g_calib_dir);       
    % save output
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir,  'mat_files' ,[func_name sprintf('_out%d.mat',g_temp_count)]);
        save(fn, 'finishedHeating', 'calibPassed', 'results', 'metrics', 'Invalid_Frames');
    end
    if (origFinishedHeating~=0)
        g_temp_count = 0;
    else
        g_temp_count = g_temp_count + 1; 
    end
    if(exist('fid','var'))
        fclose(fid);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [finishedHeating,calibPassed, results, metrics, Invalid_Frames]  = TmptrDataFrame_Calc_int(finishedHeating, regs, eepromRegs, FrameData,height , width, frameBytes,calibParams,maxTime2Wait,output_dir,fprintff,calib_dir)
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
Invalid_Frames = [];

persistent Index
persistent prevTmp
persistent prevTime
persistent lastZFrames
persistent diskObject

if isempty(Index) || (g_temp_count == 0)
    Index     = 0;
    prevTmp   = 0;  %hw.getLddTemperature();
    prevTime  = 0;
    lastZFrames = nan([runParams.calibRes,calibParams.warmUp.nFramesForZStd]);
    diskObject = strel('disk',calibParams.roi.diskSz);

end
% add error checking;

if ~finishedHeating % heating stage
    frame = Calibration.aux.convertBytesToFrames(frameBytes, [height, width], [calibParams.gnrl.rgb.res(2), calibParams.gnrl.rgb.res(1)], true);
    binLargest = maxAreaMask(frame.i>0); % In case of small spherical scale factor that causes weird striped to appear
    zForStd = nan(size(frame.z));
    zForStd(binLargest) = frame.z(binLargest);
    lastZFrames(:,:,mod(Index,calibParams.warmUp.nFramesForZStd)+1) = zForStd;
    FrameData.ptsWithZ = cornersData(frame,regs,calibParams);
    FrameData.ptsWithZ = applyDsmTransformation(FrameData.ptsWithZ, regs, 'inverse'); % avoid using soon-to-be-obsolete DSM values
    [FrameData.minMaxMemsAngX,FrameData.minMaxMemsAngY] = minMaxDSMAngles(regs,lastZFrames,calibParams,diskObject);
    results.nCornersDetected = sum(~isnan(FrameData.ptsWithZ(:,1)));
    framesData = acc_FrameData(FrameData);
    
    if(Index == 0)
        prevTmp   = FrameData.temp.ldd;
        prevTime  = FrameData.time;
    end
    Index = Index+1;
    i = Index;

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
    framesData = acc_FrameData([]); % avoid using last frame, captured after fine DSM calibration
    for iFrame = 1:length(framesData)
        framesData(iFrame).ptsWithZ = applyDsmTransformation(framesData(iFrame).ptsWithZ, regs, 'direct'); % recreate corners with up-to-date DSM values
    end
    data.framesData = framesData;
    data.regs = regs;
    
    save(fullfile(output_dir,'mat_files','data_in.mat'),'data','calibParams','runParams','regs','eepromRegs');
    
    invalidFrames = arrayfun(@(j) isempty(data.framesData(j).ptsWithZ),1:numel(data.framesData));
    data.framesData = data.framesData(~invalidFrames);
    data.dfzRefTmp = regs.FRMW.dfzCalTmp;
    [table,results, Invalid_Frames] = Calibration.thermal.generateFWTable(data,calibParams,runParams,fprintff);
    data.tableResults = results;
    [data] = Calibration.thermal.applyThermalFix(data,regs,[],calibParams,runParams,1);
    results.yDsmLosDegredation = data.tableResults.yDsmLosDegredation;
    results = UpdateResultsStruct(results); % output single layer results struct
    if isempty(table)
        calibPassed = 0;
        save(fullfile(output_dir,'mat_files' ,'data.mat'),'data','calibParams','runParams','eepromRegs');
        fprintff('table is empty (no checkerboard where found)\n');
        return;
    end
    
    [data] = Calibration.thermal.analyzeFramesOverTemperature(data,calibParams,runParams,fprintff,0);
    save(fullfile(output_dir,'mat_files' ,'data_out.mat'),'data','calibParams','runParams','eepromRegs');
    
    Calibration.aux.logResults(data.results,runParams);
    %% merge all scores outputs
    metrics = data.results;
    calibPassed = Calibration.aux.mergeScores(data.results,calibParams.errRange,fprintff);
    
    %% Burn 2 device
    fprintff('Preparing thermal calibration data for burning\n');
    Calibration.thermal.generateTableForBurning(eepromRegs, data.tableResults.table,calibParams,runParams,fprintff,0,data,calib_dir);
    fprintff('Thermal calibration finished\n');
    
end
    
% update ptsWithZ per frame
% update persistent table 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [a] = acc_FrameData(a)
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
function [binLargest] = maxAreaMask(binaryIm)
CC = bwconncomp(binaryIm);
numPixels = cellfun(@numel,CC.PixelIdxList);
[~,idx] = max(numPixels);
binLargest = zeros(size(binaryIm),'logical');
binLargest(CC.PixelIdxList{idx}) = 1;

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ptsWithZ] = cornersData(frame,regs,calibParams)
    sz = size(frame.i);
    pixelCropWidth = sz.*calibParams.gnrl.cropFactors;
    frame.i([1:pixelCropWidth(1),round(sz(1)-pixelCropWidth(1)):sz(1)],:) = 0;
    frame.i(:,[1:pixelCropWidth(2),round(sz(2)-pixelCropWidth(2)):sz(2)]) = 0;
    
    if isempty(calibParams.gnrl.cbGridSz)
        [pts,colors] = Calibration.aux.CBTools.findCheckerboardFullMatrix(frame.i, 1, [], [], calibParams.gnrl.nonRectangleFlag);
        pts = reshape(pts,[],2);
        gridSize = [size(pts,1),size(pts,2),1];
        if isfield(frame,'yuy2')
            [ptsColor,~] = Calibration.aux.CBTools.findCheckerboardFullMatrix(frame.yuy2, 0, [], [], calibParams.gnrl.rgb.nonRectangleFlag);
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
            [ptsColor,gridSize] = Validation.aux.findCheckerboard(frame.yuy2,calibParams.gnrl.cbGridSz); % p - 3 checkerboard points. bsz - checkerboard dimensions.
            if ~isequal(gridSize, calibParams.gnrl.cbGridSz)
                warning('Checkerboard not detected in color image. All of the target must be included in the image');
                ptsWithZ = [];
                return;
            end
        end
    end
    assert(regs.DIGG.sphericalEn==1, 'Frames for ATC must be captured in spherical mode')
    if isempty(colors)
        rpt = Calibration.aux.samplePointsRtd(frame.z,pts,regs);
    else
        rpt = Calibration.aux.samplePointsRtd(frame.z,reshape(pts,20,28,2),regs,0,colors,calibParams.gnrl.sampleRTDFromWhiteCheckers);
    end
    rpt(:,1) = rpt(:,1) - regs.DEST.txFRQpd(1);
    ptsWithZ = [rpt,reshape(pts,[],2)]; % without XYZ which is not calibrated well at this stage
    ptsWithZ(isnan(ptsWithZ(:,1)),:) = nan;
    if isfield(frame,'yuy2')
        ptsWithZ = [ptsWithZ,reshape(ptsColor,[],2)];
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [merged] = struct_merge(existing , new )
    merged = existing;
    % overriding merged with new
    f = fieldnames(new);
    for i = 1:length(f)
        fn = fieldnames(new.(f{i}));
        for n = 1:length(fn)
            merged.(f{i}).(fn{n}) = new.(f{i}).(fn{n});
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function results = UpdateResultsStruct(results)
    results.thermalRtdRefTemp       = results.rtd.refTemp;
    results.thermalRtdSlope         = results.rtd.slope;
    results.thermalMinCalTemp       = results.rtd.origMinval;
    results.thermalMaxCalTemp       = results.rtd.origMaxval;
    results.thermalMaSlope          = results.ma.slope;
    results.thermalAngyMinAbsScale  = min(abs(results.angy.scale));
    results.thermalAngyMaxAbsScale  = max(abs(results.angy.scale));
    results.thermalAngyMinAbsOffset = min(abs(results.angy.offset));
    results.thermalAngyMaxAbsOffset = max(abs(results.angy.offset));
    results.thermalAngyMinVal       = results.angy.minval;
    results.thermalAngyMaxVal       = results.angy.maxval;
    results.thermalAngxMinAbsScale  = min(abs(results.angx.scale));
    results.thermalAngxMaxAbsScale  = max(abs(results.angx.scale));
    results.thermalAngxMinAbsOffset = min(abs(results.angx.offset));
    results.thermalAngxMaxAbsOffset = max(abs(results.angx.offset));
    results.thermalAngxP0x          = results.angx.p0(1);
    results.thermalAngxP0y          = results.angx.p0(2);
    results.thermalAngxP1x          = results.angx.p1(1);
    results.thermalAngxP1y          = results.angx.p1(2);
    results = rmfield(results, {'rtd', 'ma', 'angy', 'angx', 'table'});
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
