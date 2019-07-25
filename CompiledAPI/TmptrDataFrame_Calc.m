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
        save(fn,'regs','eepromRegs','eepromBin', 'FrameData', 'sz' ,'InputPath','calibParams', 'maxTime2Wait' );
    end
    height = sz(1);
    width  = sz(2);
    fw = Firmware(g_calib_dir);

    if(isempty(eepromRegs) || ~isstruct(eepromRegs))
        EPROMstructure = load(fullfile(g_calib_dir,'eepromStructure.mat'));
        EPROMstructure = EPROMstructure.updatedEpromTable;
        eepromBin = uint8(eepromBin);
        eepromRegs = fw.readAlgoEpromData(eepromBin(17:end),EPROMstructure);
    end
    [regs] = struct_merge(regs , eepromRegs);
    [finishedHeating, calibPassed, results, metrics, Invalid_Frames] = TmptrDataFrame_Calc_int(finishedHeating, regs, eepromRegs, FrameData, height , width, InputPath, calibParams, maxTime2Wait, output_dir, fprintff, g_calib_dir);       
    % save output
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir,  'mat_files' ,[func_name sprintf('_out%d.mat',g_temp_count)]);
        save(fn,'finishedHeating','calibPassed', 'tableResults');
    end
    if (finishedHeating~=0)
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
frame.i = Calibration.aux.GetFramesFromDir(InputPath,width, height,'I'); % later remove local copy
frame.z = Calibration.aux.GetFramesFromDir(InputPath,width, height,'Z');
frame.i = Calibration.aux.average_images(frame.i);
frame.z = Calibration.aux.average_images(frame.z);

FrameData.ptsWithZ = cornersData(frame,regs,calibParams);
%    framesData(i) = FrameData;

framesData = acc_FrameData(FrameData);
if(Index == 0)
    
    
    prevTmp   = FrameData.temp.ldd;
    prevTime  = FrameData.time;
end
Index = Index+1;
i = Index;

if ~finishedHeating % heating stage
    if ((framesData(i).time - prevTime) >= tempSamplePeriod)
        reachedRequiredTempDiff = ((framesData(i).temp.ldd - prevTmp) < tempTh);
        reachedTimeLimit = (framesData(i).time > maxTime2WaitSec);
        reachedCloseToTKill = (framesData(i).temp.ldd > calibParams.gnrl.lddTKill-1);
        raisedFarAboveCalibTemp = (framesData(i).temp.ldd > regs.FRMW.dfzCalTmp+calibParams.warmUp.teminationTempdiffFromCalibTemp);
        
        finishedHeating = reachedRequiredTempDiff || ...
            reachedTimeLimit || ...
            reachedCloseToTKill || ...
            raisedFarAboveCalibTemp; % will come into effect in next function call
        
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
        elseif raisedFarAboveCalibTemp
            reason = 'Raised far above calib temperature';
        end
        fprintff('Finished heating reason: %s\n',reason);
    end
else % steady-state stage
    data.framesData = framesData;
    data.regs = regs;
    save(fullfile(output_dir,'mat_files','data_in.mat'),'data');
    
    invalidFrames = arrayfun(@(j) isempty(data.framesData(j).ptsWithZ),1:numel(data.framesData));
    data.framesData = data.framesData(~invalidFrames);
    data = Calibration.thermal.addEGeomToData(data);
    data.dfzRefTmp = Calibration.thermal.recalcRefTempForBetterEGeom(data,calibParams,runParams,fprintff);
    data.dfzRefTmp = regs.FRMW.dfzCalTmp;
    [table,results, Invalid_Frames] = Calibration.thermal.generateFWTable(data,calibParams,runParams,fprintff);
    data.tableResults = results;
    if isempty(table)
        calibPassed = 0;
        save(fullfile(output_dir,'mat_files' ,'data.mat'),'data');
        fprintff('table is empty (no checkerboard where found)\n');
        return;
    end
%     dataFixed = Calibration.thermal.applyFix(data,calibParams);
%     % Add eGeom to data
%     dataFixed = Calibration.thermal.addEGeomToData(dataFixed);
    
    [data] = Calibration.thermal.analyzeFramesOverTemperature(data,calibParams,runParams,fprintff,0);
    save(fullfile(output_dir,'mat_files' ,'data_out.mat'),'data');
    
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
    if isempty(calibParams.gnrl.cbGridSz)
        pts = reshape(Calibration.aux.CBTools.findCheckerboardFullMatrix(frame.i, 1),[],2);
        gridSize = [size(pts,1),size(pts,2),1];
        
    else
        [pts,gridSize] = Validation.aux.findCheckerboard(frame.i,calibParams.gnrl.cbGridSz); % p - 3 checkerboard points. bsz - checkerboard dimensions.
        if ~isequal(gridSize, calibParams.gnrl.cbGridSz)
            warning('checkerboard not detected. all target must be included in the image');
            ptsWithZ = [];
            return;
        end
    end
    if ~regs.DIGG.sphericalEn
        zIm = single(frame.z)/single(regs.GNRL.zNorm);
        zPts = interp2(zIm,pts(:,1),pts(:,2));
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
    end
    v = ptsWithZ(:,6:8);
    if size(v,1) == 20*28
        v = reshape(v,20,28,3);
        rows = find(any(~isnan(v(:,:,1)),2));
        cols = find(any(~isnan(v(:,:,1)),1));
        grd = [numel(rows),numel(cols)];
        v = reshape(v(rows,cols,:),[],3);
    else
        grd = [9,13];
    end
    [eGeom, ~, ~] = Validation.aux.gridError(v, grd, 30);
    fprintf('eGeom - %2.2f\n',eGeom);
    
end

function [merged] = struct_merge(merged , new )
    f = fieldnames(new);
    for i = 1:length(f)
        fn = fieldnames(new.(f{i}));
        for n = 1:length(fn)
            merged.(f{i}).(fn{n}) = new.(f{i}).(fn{n});
        end
    end
end