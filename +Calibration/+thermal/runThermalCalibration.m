function  [calibPassed] = runThermalCalibration(runParamsFn,calibParamsFn, fprintff)
       
    t=tic;
    if(~exist('fprintff','var'))
        fprintff=@(varargin) fprintf(varargin{:});
    end
    % runParams - Which calibration to perform.
    % calibParams - inner params that individual calibrations might use.
    [runParams,calibParams] = loadParamsXMLFiles(runParamsFn,calibParamsFn);

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
    regs = readDFZRegsForThermalCalculation(hw);
    fprintff('Done(%ds)\n',round(toc(t)));
    
    %% Start stream to load the configuration
    hw.cmd('DIRTYBITBYPASS');
    hw.cmd('algo_thermloop_en 0');
  
    [framesData,data] = Calibration.thermal.collectSelfHeatData(hw,regs,calibParams,runParams,fprintff,runParams);
    
    [table,data.results] = Calibration.thermal.generateFWTable(framesData,regs,calibParams,runParams);
    Calibration.thermal.generateAndBurnTable(hw,table);
    
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
    fprintff('Thrmal calibration finished(%d)\n',round(toc(t)));
    clear hw;
    
end
function [runParams,calibParams] = loadParamsXMLFiles(runParamsFn,calibParamsFn)
    runParams=xml2structWrapper(runParamsFn);
    %backward compatibility
    if(~isfield(runParams,'uniformProjectionDFZ'))
        runParams.uniformProjectionDFZ=true;
    end
   
    if(~exist('calibParamsFn','var') || isempty(calibParamsFn))
        %% ::load default caliration configuration
        calibParamsFn='calibParams.xml';
    end
    calibParams = xml2structWrapper(calibParamsFn);
    
end


function currregs = readDFZRegsForThermalCalculation(hw)
    
    currregs.EXTL.dsmXscale=typecast(hw.read('EXTLdsmXscale'),'single');
    currregs.EXTL.dsmYscale=typecast(hw.read('EXTLdsmYscale'),'single');
    currregs.EXTL.dsmXoffset=typecast(hw.read('EXTLdsmXoffset'),'single');
    currregs.EXTL.dsmYoffset=typecast(hw.read('EXTLdsmYoffset'),'single'); 

    DIGGspare = hw.read('DIGGspare');
    currregs.FRMW.xfov(1) = typecast(DIGGspare(2),'single');
    currregs.FRMW.yfov(1) = typecast(DIGGspare(3),'single');
    currregs.FRMW.laserangleH = typecast(DIGGspare(4),'single');
    currregs.FRMW.laserangleV = typecast(DIGGspare(5),'single');
    currregs.DEST.txFRQpd = typecast(hw.read('DESTtxFRQpd'),'single')';

    DIGGspare06 = hw.read('DIGGspare_006');
    DIGGspare07 = hw.read('DIGGspare_007');
    currregs.FRMW.calMarginL = int16(DIGGspare06/2^16);
    currregs.FRMW.calMarginR = int16(mod(DIGGspare06,2^16));
    currregs.FRMW.calMarginT = int16(DIGGspare07/2^16);
    currregs.FRMW.calMarginB = int16(mod(DIGGspare07,2^16));
    
    currregs.GNRL.imgHsize = hw.read('GNRLimgHsize');
    currregs.GNRL.imgVsize = hw.read('GNRLimgVsize');

    currregs.DEST.baseline = typecast(hw.read('DESTbaseline$'),'single');
    currregs.DEST.baseline2 = typecast(hw.read('DESTbaseline2'),'single');
    currregs.DEST.hbaseline = hw.read('DESThbaseline');
    
    currregs.FRMW.kWorld = hw.getIntrinsics();
    currregs.FRMW.kRaw = currregs.FRMW.kWorld;
    currregs.FRMW.kRaw(7) = single(currregs.GNRL.imgHsize) - 1 - currregs.FRMW.kRaw(7);
    currregs.FRMW.kRaw(8) = single(currregs.GNRL.imgVsize) - 1 - currregs.FRMW.kRaw(8);
    currregs.GNRL.zNorm = hw.z2mm;
    
    JFILspare = hw.read('JFILspare');
    currregs.FRMW.dfzCalTmp = typecast(JFILspare(2),'single');
end

