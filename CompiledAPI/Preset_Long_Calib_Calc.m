function [maxRangeScaleModRef, maxFillRate, targetDist] = Preset_Long_Calib_Calc(InputPath,cameraInput,LaserPoints,maxMod_dec,calibParams,LongRangestate)
% function [dfzRegs,results,calibPassed] = Preset_Long_Calib_Calc(InputPath,LaserPoints,maxMod_dec,sz,calibParams)
% description: 
%
% inputs:
%   InputPath -  path for input images  dir stucture InputPath\PoseN N =1:5
%        note 
%           I image naming I_*_000n.bin
%   calibParams - calibparams strcture.
%   LaserPoints - 
%   maxMod_dec -
%   sz
%   LongRangestate - 'state1' for VGA, 'state2' for XGA.                               
% output:
%   minRangeScaleModRef - 
%   ModRefDec           - 
%   


    global g_output_dir g_calib_dir g_debug_log_f g_verbose  g_save_input_flag  g_save_output_flag  g_dummy_output_flag g_fprintff g_LogFn; % g_regs g_luts;
    % setting default global value in case not initial in the init function;
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
    
    if isempty(g_calib_dir)
        g_dummy_output_flag = 0;
    end

    calib_dir = g_calib_dir;
    PresetFolder = calib_dir;
    
    func_name = dbstack;
    func_name = func_name(1).name;
    if(isempty(g_output_dir))
        output_dir = fullfile(ivcam2tempdir, func_name,'temp');
    else
        output_dir = g_output_dir;
    end
    
    if(isempty(g_fprintff)) %% HVM log file
        if(isempty(g_LogFn))
            fn = fullfile(output_dir,[func_name '_log.txt']);
        else
            fn = g_LogFn;
        end
        mkdirSafe(output_dir);
        fid = fopen(fn,'a');
        fprintff = @(varargin) fprintf(fid,varargin{:});
    else % algo_cal app_windows
        fprintff = g_fprintff; 
    end
    
    runParams.outputFolder = output_dir;
    maskParams = calibParams.presets.long.params;
    % save Input
    if g_save_input_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_in.mat']);
        save(fn,'InputPath','LaserPoints','maxMod_dec', 'cameraInput','calibParams','LongRangestate');
    end
    [maxRangeScaleModRef, maxFillRate, targetDist] = findScaleByFillRate(maskParams,runParams,calibParams,LongRangestate,InputPath,cameraInput,LaserPoints,maxMod_dec,fprintff);
    % save output
    if g_save_output_flag && exist(output_dir,'dir')~=0 
        fn = fullfile(output_dir, 'mat_files' , [func_name '_out.mat']);
        save(fn,'maxRangeScaleModRef','maxFillRate','targetDist');
    end
    if(exist('fid','var'))
        fclose(fid);
    end
end


function [maxRangeScaleModRef, maxFillRate, targetDist] = findScaleByFillRate(maskParams,runParams,calibParams,LongRangestate,inputPath,cameraInput,laserPoints,maxMod_dec,fprintff)
%% Define parameters
fillRateTh = calibParams.presets.long.(LongRangestate).fillRateTh; %97;

%% Get frames and mask
totFrames = GetLongRangeImages(inputPath,cameraInput.imSize(2),cameraInput.imSize(1));
mask = Validation.aux.getRoiCircle(cameraInput.imSize, maskParams);

%% Calculate fill rate
scores = zeros(length(totFrames),1);
oneFrame = struct('i',zeros(cameraInput.imSize(1),cameraInput.imSize(2)),'z',zeros(cameraInput.imSize(1),cameraInput.imSize(2)));
frames = repmat(oneFrame,size(totFrames(1).z,3),1);
for iScenario = 1:length(totFrames)
   for iFrame = 1:size(totFrames(iScenario).z,3)
       frames(iFrame).i = double(totFrames(iScenario).i(:,:,iFrame));
       frames(iFrame).z = double(totFrames(iScenario).z(:,:,iFrame));
       frames(iFrame).i(~mask) = nan;
       frames(iFrame).z(~mask) = nan;
   end
   [scores(iScenario,1), ~, ~] = Validation.metrics.fillRate(frames, maskParams); 
end
maxFillRate = max(scores);

%% Plot
ff1 = Calibration.aux.invisibleFigure;
plot(laserPoints,scores); title('Mean fill rate Vs. modulation ref'); xlabel('ModRef values (decimal)'); ylabel('Fill rate');
hold on;
plot(laserPoints, repelem(fillRateTh,length(laserPoints)), 'r'); grid minor; hold off;
Calibration.aux.saveFigureAsImage(ff1,runParams,'Presets','Long_Range_Laser_Calib_FR',1,1);
ff1 = Calibration.aux.invisibleFigure;
plot(laserPoints,scores); title('Mean fill rate Vs. modulation ref'); xlabel('ModRef values (decimal)'); ylabel('Fill rate');
hold on;
plot(laserPoints, repelem(fillRateTh,length(laserPoints)), 'r'); grid minor; hold off;
Calibration.aux.saveFigureAsImage(ff1,runParams,'Presets','Long_Range_Laser_Calib_FR',1,0);
ff2 = Calibration.aux.invisibleFigure;
subplot(2,1,1);imagesc(imfuse(totFrames(end).i(:,:,end),mask));title('IR image with ROI mask');
subplot(2,1,2);imagesc(imfuse(totFrames(end).z(:,:,end),mask));title('Depth (not normalized) image with ROI mask');
Calibration.aux.saveFigureAsImage(ff2,runParams,'Presets','Long_Range_Laser_Calib_mask',1);imagesc(imfuse(frames(1).z,mask));title('Depth (not normalized) image with ROI mask');

%% Find laser scale
zIm = {frames.z};
zIm = cellfun(@(x) x(:)./double(cameraInput.z2mm), zIm,'UniformOutput',false);
zIm_mean = cellfun(@(x) x(x(:)~=0), zIm,'UniformOutput', false);
zIm_mean = cellfun(@nanmean, zIm_mean,'UniformOutput', false);
zIm_mean = nanmean(cell2mat(zIm_mean));
targetDist = zIm_mean; %In mm units
if (targetDist < calibParams.errRange.(['targetDist_',LongRangestate])(1)) || (targetDist > calibParams.errRange.(['targetDist_',LongRangestate])(2))
    maxRangeScaleModRef = 1;
    fprintff(['[-] Long range preset calibration: the target is placed in the wrong location. It should be at ' num2str(mean(calibParams.errRange.(['targetDist_',LongRangestate]))) '[mm] but it is at ' num2str(targetDist) ' [mm]. Modulation ref will remain at max value\n']);  
    return;
end
ix = find(scores >= fillRateTh, 1);
if isempty(ix)
    maxRangeScaleModRef = 1;
    fprintff(['[-] Long range preset calibration: no fill rate found above threshold = ' num2str(fillRateTh) ' %% \n']);
    return;
end
startIx = max(ix-1,1); endIx = min(ix+1,length(scores));
bestIx = startIx:endIx;
[~,ix_min]= min(abs(scores(bestIx) - fillRateTh));
maxRangeScaleModRef = round(laserPoints(bestIx(ix_min)))/maxMod_dec;

%% prepare output script
if calibParams.presets.long.updateCalibVal
    longRangePresetFn = fullfile(runParams.outputFolder,'AlgoInternal','longRangePreset.csv');
    longRangePreset=readtable(longRangePresetFn);
    modRefInd=find(strcmp(longRangePreset.name,calibParams.presets.long.(LongRangestate).ModRefPresetState));
    longRangePreset.value(modRefInd) = maxRangeScaleModRef;
    writetable(longRangePreset,longRangePresetFn);
end
end



function [frames] = GetLongRangeImages(InputPath,width,height)
d = dir(InputPath);
isub = [d(:).isdir]; %# returns logical vector
nameFolds = {d(isub).name}';
nameFolds(ismember(nameFolds,{'.','..'})) = [];
nameFolds = sort(nameFolds);
for k = 1:numel(nameFolds)
    path = fullfile(InputPath,nameFolds{k});
    frames(k).z = Calibration.aux.GetFramesFromDir(path,width, height,'Z');
    frames(k).i = Calibration.aux.GetFramesFromDir(path,width, height,'I');
end
end


