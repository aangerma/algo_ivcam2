function  [validationPassed] = runThermalValidation(runParams,calibParams, fprintff)
       
    t=tic;
    if(~exist('fprintff','var'))
        fprintff=@(varargin) fprintf(varargin{:});
    end
    
    fprintff('Starting thermal validation...\n');
    
    
    
    %% Load hw interface
    fprintff('Loading HW interface...');
    hw=HWinterface();
    fprintff('Done(%ds)\n',round(toc(t)));
    
    %% Get regs state
    fprintff('Reading unit calibration regs...');
    data.regs = Calibration.thermal.readDFZRegsForThermalCalculation(hw);
    fprintff('Done(%ds)\n',round(toc(t)));
    
    %% Start stream to load the configuration
    hw.cmd('DIRTYBITBYPASS');
  
    
    data = Calibration.thermal.collectSelfHeatData(hw,data,calibParams,runParams,fprintff,calibParams.validation.maximalCoolingAndHeatingTimes);
    data.results = Calibration.thermal.analyzeFramesOverTemperature(data,calibParams,runParams,fprintff);
    
    % Option two - partial validation, let it cool down to N degrees below calibration temperature and then compare to calibration temperature 
    
    save(fullfile(runParams.outputFolder,'validationData.mat'),'data');

    
   
    %% merge all scores outputs
    validationPassed = Calibration.aux.mergeScores(data.results,calibParams.validationErrRange,fprintff);
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


