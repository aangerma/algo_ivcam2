function [finishedHeating, calibPassed, results, metrics, Invalid_Frames]  = TmptrDataFrame_Calc(finishedHeating, regs, eepromRegs, eepromBin, FrameData, sz ,InputPath, calibParams, maxTime2Wait)

%function [result, data ,table]  = TemDataFrame_Calc(regs, FrameData, sz ,InputPath,calibParams, maxTime2Wait)
% description: initiale set of the DSM scale and offset 
%
% inputs:
%   regs      - register list for calculation (zNorm ,kRaw ,hbaseline
%   ,baseline ,xfov ,yfov ,laserangleH ,laserangleV)
%   FrameData - structure of device state during frame capturing (varity temprature sensor , iBias , vBias etc) 
%   InputPath - I & Z image of the checkerboard
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
    global g_output_dir g_calib_dir g_debug_log_f g_verbose  g_save_input_flag  g_save_output_flag  g_dummy_output_flag g_fprintff g_temp_count g_LogFn; % g_regs g_luts;
    fprintff = g_fprintff;
    
    % setting default global value in case not initial in the init function;
    if isempty(g_temp_count)
        g_temp_count = 0;
    end
    if isempty(g_debug_log_f)
        g_debug_log_f = 0;
    end
    if isempty(g_verbose)
        g_verbose = 0;
    end
    if isempty(g_save_input_flag)
        g_save_input_flag = 0;
    end
    if isempty(g_save_output_flag)
        g_save_output_flag = 0;
    end
    if isempty(g_dummy_output_flag)
        g_dummy_output_flag = 0;
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
        save(fn,'finishedHeating','regs', 'eepromRegs','eepromBin', 'FrameData', 'sz' ,'InputPath','calibParams', 'maxTime2Wait' );
    end
    height = sz(1);
    width  = sz(2);
    fw = Firmware(g_calib_dir);

    if(isempty(eepromRegs) || ~isstruct(eepromRegs))
        EPROMstructure = load(fullfile(g_calib_dir,'eepromStructure.mat'));
        EPROMstructure = EPROMstructure.updatedEpromTable;
        eepromBin = uint8(eepromBin);
        eepromRegs = fw.readAlgoEpromData(eepromBin(17:end),EPROMstructure);
        [regs] = struct_merge(regs , eepromRegs);
    end
    origFinishedHeating = finishedHeating;
    [finishedHeating, calibPassed, results, metrics, Invalid_Frames] = TmptrDataFrame_Calc_int(finishedHeating, regs, eepromRegs, FrameData, height , width, InputPath, calibParams, maxTime2Wait, output_dir, fprintff, g_calib_dir);       
    % save output
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir,  'mat_files' ,[func_name sprintf('_out%d.mat',g_temp_count)]);
        save(fn,'finishedHeating','calibPassed', 'results');
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

function [finishedHeating,calibPassed, results, metrics, Invalid_Frames]  = TmptrDataFrame_Calc_int(finishedHeating, regs, eepromRegs, FrameData,height , width, InputPath,calibParams,maxTime2Wait,output_dir,fprintff,calib_dir)
% description: initiale set of the DSM scale and offset 
%
% inputs:
%   regs      - register list for calculation (zNorm ,kRaw ,hbaseline
%   ,baseline ,xfov ,yfov ,laserangleH ,laserangleV)
%   FrameData - structure of device state during frame capturing (varity temprature sensor , iBias , vBias etc) 
%   InputPath - I & Z image of the checkerboard
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
results = [];
metrics = [];
Invalid_Frames = [];

persistent Index
persistent prevTmp
persistent prevTime

if isempty(Index) || (g_temp_count == 0)
    Index     = 0;
    prevTmp   = 0;  %hw.getLddTemperature();
    prevTime  = 0;
end
% add error checking;

if ~finishedHeating % heating stage
    frame.i = Calibration.aux.GetFramesFromDir(InputPath,width, height,'I'); % later remove local copy
    frame.z = Calibration.aux.GetFramesFromDir(InputPath,width, height,'Z');
    frame.i = Calibration.aux.average_images(frame.i);
    frame.z = Calibration.aux.average_images(frame.z);
    FrameData.ptsWithZ = cornersData(frame,regs,calibParams);
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
    data.framesData = framesData;
    data.regs = regs;
    save(fullfile(output_dir,'mat_files','data_in.mat'),'data');
    
    invalidFrames = arrayfun(@(j) isempty(data.framesData(j).ptsWithZ),1:numel(data.framesData));
    data.framesData = data.framesData(~invalidFrames);
    data.dfzRefTmp = regs.FRMW.dfzCalTmp;
    [table,results, Invalid_Frames] = Calibration.thermal.generateFWTable(data,calibParams,runParams,fprintff);
    data.tableResults = results;
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

function [a] = acc_FrameData(a)
    global acc;
    acc = [acc; a] ;
    a = acc;
end



function [ptsWithZ] = cornersData(frame,regs,calibParams)
    sz = size(frame.i);
    pixelCropWidth = sz.*calibParams.gnrl.cropFactors;
    frame.i([1:pixelCropWidth(1),round(sz(1)-pixelCropWidth(1)):sz(1)],:) = 0;
    frame.i(:,[1:pixelCropWidth(2),round(sz(2)-pixelCropWidth(2)):sz(2)]) = 0;
    
    if isempty(calibParams.gnrl.cbGridSz)
        [pts,colors] = Calibration.aux.CBTools.findCheckerboardFullMatrix(frame.i, 1);
        pts = reshape(pts,[],2);
        gridSize = [size(pts,1),size(pts,2),1];
        
    else
        colors = [];
        [pts,gridSize] = Validation.aux.findCheckerboard(frame.i,calibParams.gnrl.cbGridSz); % p - 3 checkerboard points. bsz - checkerboard dimensions.
        if ~isequal(gridSize, calibParams.gnrl.cbGridSz)
            warning('checkerboard not detected. all target must be included in the image');
            ptsWithZ = [];
            return;
        end
    end
    assert(regs.DIGG.sphericalEn==1, 'Frames for ATC must be captured in spherical mode')
    if isempty(colors)
        rpt = Calibration.aux.samplePointsRtd(frame.z,pts,regs);
    else
        rpt = Calibration.aux.samplePointsRtdAdvanced(frame.z,reshape(pts,20,28,2),regs,colors,0,calibParams.gnrl.sampleRTDFromWhiteCheckers);
    end
    rpt(:,1) = rpt(:,1) - regs.DEST.txFRQpd(1);
    ptsWithZ = [rpt,reshape(pts,[],2)]; % without XYZ which is not calibrated well at this stage
    ptsWithZ(isnan(ptsWithZ(:,1)),:) = nan;
end

function [merged] = struct_merge(merged , new )
    % regs to keep (and not override by new), namely regs calibrated in ATC
    backupRegs.EXTL.conLocDelaySlow     = merged.EXTL.conLocDelaySlow;
    backupRegs.EXTL.conLocDelayFastC    = merged.EXTL.conLocDelayFastC;
    backupRegs.EXTL.conLocDelayFastF    = merged.EXTL.conLocDelayFastF;
    backupRegs.EXTL.dsmXscale           = merged.EXTL.dsmXscale;
    backupRegs.EXTL.dsmXoffset          = merged.EXTL.dsmXoffset;
    backupRegs.EXTL.dsmYscale           = merged.EXTL.dsmYscale;
    backupRegs.EXTL.dsmYoffset          = merged.EXTL.dsmYoffset;
    backupRegs.FRMW.dfzCalTmp           = merged.FRMW.dfzCalTmp;
    backupRegs.FRMW.dfzApdCalTmp        = merged.FRMW.dfzApdCalTmp;
    backupRegs.FRMW.dfzVbias            = merged.FRMW.dfzVbias;
    backupRegs.FRMW.dfzIbias            = merged.FRMW.dfzIbias;
    % overriding merged with new
    f = fieldnames(new);
    for i = 1:length(f)
        fn = fieldnames(new.(f{i}));
        for n = 1:length(fn)
            merged.(f{i}).(fn{n}) = new.(f{i}).(fn{n});
        end
    end
    % undoing override for backupRegs
    f = fieldnames(backupRegs);
    for i = 1:length(f)
        fn = fieldnames(backupRegs.(f{i}));
        for n = 1:length(fn)
            merged.(f{i}).(fn{n}) = backupRegs.(f{i}).(fn{n});
        end
    end
end

function results = UpdateResultsStruct(results)
    results.thermalRtdRefTemp = results.rtd.refTemp;
    results.thermalRtdSlope = results.rtd.slope;
    results.thermalAngyMinAbsScale = min(abs(results.angy.scale));
    results.thermalAngyMaxAbsScale = max(abs(results.angy.scale));
    results.thermalAngyMinAbsOffset = min(abs(results.angy.offset));
    results.thermalAngyMaxAbsOffset = max(abs(results.angy.offset));
    results.thermalAngyMinVal = results.angy.minval;
    results.thermalAngyMaxVal = results.angy.maxval;
    results.thermalAngxMinAbsScale = min(abs(results.angx.scale));
    results.thermalAngxMaxAbsScale = max(abs(results.angx.scale));
    results.thermalAngxMinAbsOffset = min(abs(results.angx.offset));
    results.thermalAngxMaxAbsOffset = max(abs(results.angx.offset));
    results.thermalAngxP0x = results.angx.p0(1);
    results.thermalAngxP0y = results.angx.p0(2);
    results.thermalAngxP1x = results.angx.p1(1);
    results.thermalAngxP1y = results.angx.p1(2);
    results = rmfield(results, {'rtd', 'angy', 'angx', 'table'});
end