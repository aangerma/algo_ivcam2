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
    data.regs = Calibration.thermal.readDFZRegsForThermalCalculation(hw,0,calibParams,runParams);
    fprintff('Done(%ds)\n',round(toc(t)));
    
    %% Start stream to load the configuration
    
    
    runParams.manualCaptures = 0;
    data = Calibration.thermal.collectSelfHeatData(hw,data,calibParams,runParams,fprintff,calibParams.validation.maximalCoolingAndHeatingTimes,app,1);
    save(fullfile(runParams.outputFolder,'validationData.mat'),'data','calibParams','runParams');
    data.camerasParams = getCamerasParams(hw,runParams,calibParams);
    [data] = Calibration.thermal.analyzeFramesOverTemperature(data,calibParams,runParams,fprintff,1);
    
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
