function  [validationPassed] = runThermalValidation(runParams,calibParams, fprintff,spark,app)
    if(~exist('spark','var'))
        spark=[];
    end
    write2spark = ~isempty(spark);
    t=tic;
    if(~exist('fprintff','var'))
        fprintff=@(varargin) fprintf(varargin{:});
    end
    
    fprintff('Starting thermal validation...\n');
    
    
    
    %% Load hw interface
    fprintff('Loading HW interface...');
    hw=HWinterface();
    hw.cmd('DIRTYBITBYPASS');
    Calibration.thermal.setTKillValues(hw,calibParams,fprintff);
    hw.setPresetControlState(calibParams.gnrl.presetMode);
    fprintff('Done(%ds)\n',round(toc(t)));
    %% Get regs state
    fprintff('Reading unit calibration regs...');
    hw.startStream(0,runParams.calibRes);
    hw.stopStream;
    calibParams.gnrl.sphericalMode = 0;
    internalFolder = fullfile(runParams.outputFolder,'AlgoInternal');
    mkdirSafe(internalFolder);
    confScriptFolder = fullfile(fileparts(mfilename('fullpath')),'+confidenceScipt');
    copyfile(fullfile(confScriptFolder,'*.*'),  internalFolder);
    
    
    data.regs = Calibration.thermal.readDFZRegsForThermalCalculation(hw,0,calibParams,runParams);
    if isfield(calibParams.gnrl, 'rgb') && isfield(calibParams.gnrl.rgb, 'fixRgbThermal') && calibParams.gnrl.rgb.fixRgbThermal
        [data.rgb] = Calibration.thermal.readDataForRgbThermalCalculation(hw,calibParams);
    end
    fprintff('Done(%ds)\n',round(toc(t)));
    
    %% Start stream to load the configuration
    
    
    runParams.manualCaptures = 0;
    data = Calibration.thermal.collectSelfHeatData(hw,data,calibParams,runParams,fprintff,calibParams.validation.maximalCoolingAndHeatingTimes,app,1);
    data.camerasParams = getCamerasParams(hw,runParams,calibParams);
    data.dutyCycle2Conf = readtable(fullfile(confScriptFolder,'dutyCycle2Conf.csv'));
    save(fullfile(runParams.outputFolder,'validationData.mat'),'data','calibParams','runParams');
    [data] = Calibration.thermal.analyzeFramesOverTemperature(data,calibParams,runParams,fprintff,1);
    saveTemperaturesGraph(data,runParams);
    saveIRGraph(data,runParams);
    % Option two - partial validation, let it cool down to N degrees below calibration temperature and then compare to calibration temperature 
    
    save(fullfile(runParams.outputFolder,'validationData.mat'),'data','calibParams','runParams');

    
   
    %% merge all scores outputs
    data.results.fillRateStart = data.validFillRatePrc(1);
    data.results.fillRateEnd = data.validFillRatePrc(2);
    validationPassed = Calibration.aux.mergeScores(data.results,calibParams.validationErrRange,fprintff);
    Calibration.aux.writeResults2Spark(data.results,spark,calibParams.validationErrRange,write2spark,'Algo2Val');

    fprintff('[!] Validation ended - ');
    if(validationPassed==0)
        fprintff('FAILED.\n');
    else
        fprintff('PASSED.\n');
    end
    %% Burn 2 device
    fprintff('Thermal validation finished(%d)\n',round(toc(t)));
    clear hw;
    
end

function [camerasParams] = getCamerasParams(hw,runParams,calibParams)
[ ~,b] = hw.cmd('RGB_INTRINSICS_GET');
intr = typecast(b,'single');
Krgb = eye(3);
Krgb([1,5,7,8,4]) = intr([calibParams.gnrl.rgb.startIxRgb:calibParams.gnrl.rgb.startIxRgb+3,1]);%intr([6:9,1]);
drgb = intr(calibParams.gnrl.rgb.startIxRgb+4:calibParams.gnrl.rgb.startIxRgb+8);
[ ~,b] = hw.cmd('RGB_EXTRINSICS_GET');
extr = typecast(b,'single');
Rrgb = reshape(extr(1:9),[3 3])';
Trgb = extr(10:12)';
camerasParams.rgbRes = calibParams.gnrl.rgb.res;
camerasParams.rgbPmat = Krgb*[Rrgb Trgb];
camerasParams.rgbDistort = drgb;
camerasParams.Krgb = Krgb;
camerasParams.depthRes = runParams.calibRes;
camerasParams.zMaxSubMM = hw.z2mm;
camerasParams.Kdepth = hw.getIntrinsics;
end

function [] = saveTemperaturesGraph(data,runParams)

temp = [data.framesData.temp];
fnames = fieldnames(temp);
times = [data.framesData.time];
ff = Calibration.aux.invisibleFigure;
hold on;
for i = 1:numel(fnames)
    plot(times,[temp.(fnames{i})]);
end
legend(fnames);
grid minor;
title('Heating Stage');xlabel('sec');ylabel('Temperatures [degrees]');
Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('TemperatureReadings'),1);
end
function saveIRGraph(data,runParams)
%% IR statistics
temp = [data.framesData.temp];
ldd = [temp.ldd];
framesData = data.framesData;
if isfield(framesData, 'irStat')
    irData = [framesData.irStat];
    irMean = [irData.mean];
    irStd = [irData.std];
    irNumPix = [irData.nPix];
    if ~isempty(runParams) && isfield(runParams, 'outputFolder')
        ff = Calibration.aux.invisibleFigure;
        hold on
        plot(ldd, irMean, 'b')
        plot(ldd, irMean+irStd, 'r--')
        plot(ldd, irMean-irStd, 'r--')
        title(sprintf('IR in central white tiles (%.1f+-%.1f pixels)', mean(irNumPix), std(irNumPix)));
        grid on; xlabel('LDD [deg]'); ylabel('IR');
        legend('mean', 'STD margin')
        Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('IR_statistics'));
    end
end

end