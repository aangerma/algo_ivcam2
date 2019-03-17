function  [calibPassed] = runThermalCalibration(runParamsFn,calibParamsFn, fprintff)
       
    t=tic;
    if(~exist('fprintff','var'))
        fprintff=@(varargin) fprintf(varargin{:});
    end
    % runParams - Which calibration to perform.
    % calibParams - inner params that individual calibrations might use.
    [runParams,calibParams] = loadParamsXMLFiles(runParamsFn,calibParamsFn);
    if ~runParams.performCalibration
       fprintff('Skipping calibration stage...\n'); 
       calibPassed = 1;
       return;
    end
    fprintff('Starting thermal calibration:\n');
    fprintff('%-15s %s\n','stated at',datestr(now));
    fprintff('%-15s %5.2f.%1.0f\n','version',runParams.version,runParams.subVersion);
    
    
    
    %% Load hw interface
    fprintff('Loading HW interface...');
    hw=HWinterface();
    fprintff('Done(%ds)\n',round(toc(t)));
    
    [~,serialNum,isGen1] = hw.getInfo(); 
    fprintff('%-15s %8s\n','serial',serialNum);
    if isGen1
        fprintff('Unit is gen1 ID    \n');
    else
        fprintff('Unit is demo board    \n');
    end
    
    %% Get regs state
    fprintff('Reading unit calibration regs...');
    data.regs = Calibration.thermal.readDFZRegsForThermalCalculation(hw);
    fprintff('Done(%ds)\n',round(toc(t)));
    fprintff('Algo Calib Temp: %2.2fdeg\n',data.regs.FRMW.dfzCalTmp);
    
    
    %% Start stream to load the configuration
    hw.cmd('DIRTYBITBYPASS');
    hw.cmd('algo_thermloop_en 0');
  
    data = Calibration.thermal.collectSelfHeatData(hw,data,calibParams,runParams,fprintff,[]);
    [table,data.processed] = Calibration.thermal.generateFWTable(data.framesData,data.regs,calibParams,runParams,fprintff);
    
    if isempty(table)
       calibPassed = 0;
       save(fullfile(runParams.outputFolder,'data.mat'),'data');
       return;
    end
    [data.results] = Calibration.thermal.analyzeFramesOverTemperature(data,calibParams,runParams,fprintff);
    save(fullfile(runParams.outputFolder,'data.mat'),'data');
    
   
    Calibration.aux.logResults(data.results,runParams);
    %% merge all scores outputs
    calibPassed = Calibration.aux.mergeScores(data.results,calibParams.errRange,fprintff);
    
        
    fprintff('[!] Calibration ended - ');
    if(calibPassed==0)
        fprintff('FAILED.\n');
    else
        fprintff('PASSED.\n');
    end
    %% Burn 2 device
    fprintff('Burning thermal calibration\n',round(toc(t)));
    Calibration.thermal.generateAndBurnTable(hw,table,calibParams,runParams,fprintff,calibPassed);
    fprintff('Thrmal calibration finished(%d)\n',round(toc(t)));
    clear hw;
    
end
function [runParams,calibParams] = loadParamsXMLFiles(runParamsFn,calibParamsFn)
    runParams=xml2structWrapper(runParamsFn);
    calibParams = xml2structWrapper(calibParamsFn);
    
end

