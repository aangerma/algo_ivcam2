function  [calibPassed,score] = runCalibStream(runParamsFn,calibParamsFn, fprintff)
       
    t=tic;
    score=0;
    results = struct;
    if(~exist('fprintff','var'))
        fprintff=@(varargin) fprintf(varargin{:});
    end
    % runParams - Which calibration to perform.
    % calibParams - inner params that individual calibrations might use.
    [runParams,calibParams] = loadParamsXMLFiles(runParamsFn,calibParamsFn);
    if noCalibrations(runParams)
        calibPassed = -1;
        return;
    end
    %% Calibration file names
    [runParams,fnCalib,fnUndsitLut] = defineFileNamesAndCreateResultsDir(runParams);
    
    fprintff('Starting calibration:\n');
    fprintff('%-15s %s\n','stated at',datestr(now));
    fprintff('%-15s %5.2f\n','version',runParams.version);
    
    %% Load init fw
    fprintff('Loading initial firmware...');
    fw = Pipe.loadFirmware(runParams.internalFolder);
    [regs,luts]=fw.get();%run autogen
    fprintff('Done(%ds)\n',round(toc(t)));
    
    %% Load hw interface
    hw = loadHWInterface(runParams,fw,fprintff,t);
    
    % Verify unit's configuration version
    verValue = getVersion(hw,runParams);  
    
    %% Update init configuration
    updateInitConfiguration(hw,fw,fnCalib,runParams);
    %% Init hw configuration
    initConfiguration(hw,fw,runParams,fprintff,t);
    
    %% Get a single frame to see that the unit functions
    fprintff('opening stream...');
    hw.getFrame();
    fprintff('Done(%ds)\n',round(toc(t)));
     
    %% Set coarse DSM values 
    calibrateCoarseDSM(hw, runParams, calibParams, fprintff,t);

    %% ::calibrate delays::
    [results,calibPassed] = calibrateDelays(hw, runParams, calibParams, results, fw, fnCalib, fprintff);
    if ~calibPassed
        return;
    end
    
    %% ::dsm calib::
    calibrateDSM(hw, fw, runParams, calibParams,fnCalib, fprintff,t);
    
   
    %% ::gamma:: 
    results = calibrateGamma(runParams, calibParams, results, fprintff, t);
    
    %% ::DFZ::  Apply DFZ result if passed (It affects next calibration stages)
    [results,calibPassed] = calibrateDFZ(hw, regs, runParams, calibParams, results,fw,fnCalib, fprintff, t);
    if ~calibPassed
       return 
    end

    
    %% ::roi::
    [results] = calibrateROI(hw, runParams, calibParams, results,fw,fnCalib, fprintff, t);
    
    %% write version+intrinsics
    writeVersionAndIntrinsics(verValue,fw,fnCalib);
    
    %% ::Fix ang2xy Bug using undistort table::
    [results,luts] = fixAng2XYBugWithUndist(hw, runParams, calibParams, results,fw, fnCalib, fprintff, t);

    
    
    % Update fnCalin and undist lut in output dir
    fw.writeUpdated(fnCalib);
    io.writeBin(fnUndsitLut,luts.FRMW.undistModel);
    
    %% merge all scores outputs
    score = mergeScores(results,runParams,calibParams,fprintff);
    
    fprintff('[!] calibration ended - ');
    if(score==0)
        fprintff('FAILED.\n');
    elseif(score<calibParams.passScore)
        fprintff('QUALITY FAILED.\n');
    else
        fprintff('PASSED.\n');
    end
    
    %% Burn 2 device
    burn2Device(hw,score,runParams,calibParams,fprintff,t);
    
    calibPassed = (score>=calibParams.passScore);
    fprintff('Calibration finished(%d)\n',round(toc(t)));
    
    %% Validation
    clear hw;
%     Calibration.validation.validateCalibration(runParams,calibParams,fprintff);
    
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
function [runParams,fnCalib,fnUndsitLut] = defineFileNamesAndCreateResultsDir(runParams)
    
    runParams.internalFolder = fullfile(runParams.outputFolder,'AlgoInternal');
    mkdirSafe(runParams.outputFolder);
    mkdirSafe(runParams.internalFolder);
    fnCalib     = fullfile(runParams.internalFolder,'calib.csv');
    fnUndsitLut = fullfile(runParams.internalFolder,'FRMWundistModel.bin32');
    initFldr = fullfile(fileparts(mfilename('fullpath')),'initScript');
    copyfile(fullfile(initFldr,'*.csv'), runParams.internalFolder)
    
end

function hw = loadHWInterface(runParams,fw,fprintff,t)
    fprintff('Loading HW interface...');
    if isfield(runParams,'replayFile')
        hwRecFile = runParams.replayFile;
    else
        hwRecFile = [];
    end
    
    if runParams.replayMode
        if(exist(hwRecFile,'file'))
            % Use recorded session
            hw=HWinterfaceFile(hwRecFile);
            fprintff('Loading recorded capture(%s)\n',hwRecFile);
            
        else
            error('no file found in %s\n',hwRecFile)
        end
    else
        hw=HWinterface(fw,fullfile(runParams.outputFolder,'sessionRecord.mat'));
        
    end
    fprintff('Done(%ds)\n',round(toc(t)));
end

function verValue = getVersion(hw,runParams)
    verValue = typecast(uint8([round(100*mod(runParams.version,1)) floor(runParams.version) 0 0]),'uint32');
    
    unitConfigVersion=hw.read('DIGGspare_005');
    if(unitConfigVersion~=verValue)
        warning('incompatible configuration versions!');
    end
end
function updateInitConfiguration(hw,fw,fnCalib,runParams)
    if ~runParams.DSM
        currregs.EXTL.dsmXscale=typecast(hw.read('EXTLdsmXscale'),'single');
        currregs.EXTL.dsmYscale=typecast(hw.read('EXTLdsmYscale'),'single');
        currregs.EXTL.dsmXoffset=typecast(hw.read('EXTLdsmXoffset'),'single');
        currregs.EXTL.dsmYoffset=typecast(hw.read('EXTLdsmYoffset'),'single'); 
    end
    if ~runParams.dataDelay
        currregs.EXTL.conLocDelaySlow = hw.read('EXTLconLocDelaySlow');
        currregs.EXTL.conLocDelayFastC = hw.read('EXTLconLocDelayFastC');
        currregs.EXTL.conLocDelayFastF = hw.read('EXTLconLocDelayFastF');
    end
    if ~runParams.DFZ
        DIGGspare = hw.read('DIGGspare');
        currregs.FRMW.xfov = typecast(DIGGspare(2),'single');
        currregs.FRMW.yfov = typecast(DIGGspare(3),'single');
        currregs.FRMW.laserangleH = typecast(DIGGspare(4),'single');
        currregs.FRMW.laserangleV = typecast(DIGGspare(5),'single');
        currregs.DEST.txFRQpd = typecast(hw.read('DESTtxFRQpd'),'single')';
    end
    if ~runParams.ROI
        DIGGspare06 = hw.read('DIGGspare_006');
        DIGGspare07 = hw.read('DIGGspare_007');
        currregs.FRMW.marginL = int16(DIGGspare06/2^16);
        currregs.FRMW.marginR = int16(mod(DIGGspare06,2^16));
        currregs.FRMW.marginT = int16(DIGGspare07/2^16);
        currregs.FRMW.marginB = int16(mod(DIGGspare07,2^16));
    end
    if any(~[runParams.DSM, runParams.dataDelay, runParams.DFZ])
        fw.setRegs(currregs,fnCalib);
        fw.get();
    end
end
function initConfiguration(hw,fw,runParams,fprintff,t)  
    fprintff('init hw configuration...');
    if(runParams.init)
        fnAlgoInitMWD  =  fullfile(runParams.internalFolder,filesep,'algoInit.txt');
        fw.genMWDcmd('^(?!MTLB|EPTG|FRMW|EXTLauxShadow.*$).*',fnAlgoInitMWD);
        hw.runPresetScript('maReset');
        pause(0.1);
        hw.runScript(fnAlgoInitMWD);
        pause(0.1);
        hw.runPresetScript('maRestart');
        pause(0.1);
        hw.runPresetScript('maReset');
        hw.runPresetScript('maRestart');
%         hw.cmd('mwd a00d01ec a00d01f0 00000001 // EXTLauxShadowUpdateFrame');
        hw.shadowUpdate();
        fprintff('Done(%ds)\n',round(toc(t)));
    else
        fprintff('skipped\n');
    end
end
function [results,calibPassed] = calibrateDelays(hw, runParams, calibParams, results, fw, fnCalib, fprintff)
    calibPassed = 1;
    fprintff('[-] Depth and IR delay calibration...\n');
    if(runParams.dataDelay)
        Calibration.dataDelay.setAbsDelay(hw,calibParams.dataDelay.slowDelayInitVal,false);
        Calibration.aux.CBTools.showImageRequestDialog(hw,1,diag([.8 .8 1]));
        [delayRegs,delayCalibResults]=Calibration.dataDelay.calibrate(hw,calibParams.dataDelay,fprintff,runParams.verbose);
        
        fw.setRegs(delayRegs,fnCalib);
        regs = fw.get();
        
        results.delayS = (1- delayCalibResults.slowDelayCalibSuccess);
        results.delaySlowPixelVar = delayCalibResults.delaySlowPixelVar;
        results.delayF = (1-delayCalibResults.fastDelayCalibSuccess);
        
        if delayCalibResults.slowDelayCalibSuccess 
            fprintff('[v] ir delay calib passed [e=%g]\n',results.delayS);
        else
            fprintff('[x] ir delay calib failed [e=%g]\n',results.delayS);
            calibPassed = 0;
        end
        
        pixVarRange = calibParams.errRange.delaySlowPixelVar;
        if  results.delaySlowPixelVar >= pixVarRange(1) &&...
                results.delaySlowPixelVar <= pixVarRange(2)
            fprintff('[v] ir vertical pixel alignment variance [e=%g]\n',results.delaySlowPixelVar);
        else
            fprintff('[x] ir vertical pixel alignment variance [e=%g]\n',results.delaySlowPixelVar);
            calibPassed = 0;
        end
        
        if delayCalibResults.fastDelayCalibSuccess
            fprintff('[v] depth delay calib passed [e=%g]\n',results.delayF);
        else
            fprintff('[x] depth delay calib failed [e=%g]\n',results.delayF);
            calibPassed = 0;
        end
        
    else
        fprintff('skipped\n');
    end
    
end
function calibrateCoarseDSM(hw, runParams, calibParams, fprintff, t)
    % Set a DSM value that makes the valid area of the image in spherical
    % mode to be above a certain threshold.
    fprintff('[-] Coarse DSM calibration...\n');
    if(runParams.DSM)
        Calibration.aux.calibCoarseDSM(hw,calibParams,runParams.verbose);
        fprintff('[v] Done(%d)\n',round(toc(t)));
    else
        fprintff('[?] skipped\n');
    end
end
function calibrateDSM(hw,fw, runParams, calibParams,fnCalib, fprintff, t)
    fprintff('[-] DSM calibration...\n');
    if(runParams.DSM)
        dsmregs = Calibration.aux.calibDSM(hw,calibParams,fprintff,runParams.verbose);
        fw.setRegs(dsmregs,fnCalib);
        fprintff('[v] Done(%d)\n',round(toc(t)));
    else
        fprintff('[?] skipped\n');
    end
    
end
function results = calibrateGamma(runParams, calibParams, results, fprintff, t)
    fprintff('[-] gamma...\n');
    if (runParams.gamma)
        %     [gammaregs,results.gammaErr] = Calibration.aux.runGammaCalib(hw,.verbose);
        %
        %     if(results.gammaErr,calibParams.errRange.gammaErr(2))
        %         fprintff('[v] gamma passed[e=%g]\n',results.gammaErr);
        %     else
        %         fprintff('[x] gamma failed[e=%g]\n',results.gammaErr);
        %         score = 0;
        %         return;
        %     end
        %     fw.setRegs(gammaregs,fnCalib);
        results.gammaErr=0;
        fprintff('[v] Done(%ds)\n',round(toc(t)));
    else
        fprintff('[?] skipped\n');
    end
end
function [results,calibPassed] = calibrateDFZ(hw, regs, runParams, calibParams, results, fw, fnCalib, fprintff, t)
    calibPassed = 1;
    fprintff('[-] FOV, System Delay, Zenith and Distortion calibration...\n');
    if(runParams.DFZ)
        calibPassed = 0;
        if(runParams.uniformProjectionDFZ)
            Calibration.aux.setLaserProjectionUniformity(hw,true);
        end
        regs.DEST.depthAsRange=true;regs.DIGG.sphericalEn=true;
        r=Calibration.RegState(hw);
        
        r.add('JFILinvBypass',true);
        r.add('DESTdepthAsRange',true);
        r.add('DIGGsphericalEn',true);
        r.set();
        
        nCorners = 9*13;
        d(1)=Calibration.aux.CBTools.showImageRequestDialog(hw,1,diag([.7 .7 1]));
        Calibration.aux.CBTools.checkerboardInfoMessage(d(1),fprintff,nCorners);
        d(2)=Calibration.aux.CBTools.showImageRequestDialog(hw,1,diag([.6 .6 1]));
        Calibration.aux.CBTools.checkerboardInfoMessage(d(2),fprintff,nCorners);
        d(3)=Calibration.aux.CBTools.showImageRequestDialog(hw,1,diag([.5 .5 1]));
        Calibration.aux.CBTools.checkerboardInfoMessage(d(3),fprintff,nCorners);
        d(4)=Calibration.aux.CBTools.showImageRequestDialog(hw,1,[.5 0 .1;0 .5 0; 0.2 0 1]);
        d(5)=Calibration.aux.CBTools.showImageRequestDialog(hw,1,[.5 0 -.1;0 .5 0; -0.2 0 1]);
%         d(6)=Calibration.aux.CBTools.showImageRequestDialog(hw,2,diag([2 2 1]));
        
        
        % dodluts=struct;
        [dfzRegs,results.geomErr] = Calibration.aux.calibDFZ(d(1:3),regs,calibParams,fprintff,0);
        r.reset();
        
        
        if(results.geomErr<calibParams.errRange.geomErr(2))
            fw.setRegs(dfzRegs,fnCalib);
            fprintff('[v] geom calib passed[e=%g]\n',results.geomErr);
            fnAlgoTmpMWD =  fullfile(runParams.internalFolder,filesep,'algoValidCalib.txt');
            [regs,luts]=fw.get();%run autogen
            fw.genMWDcmd('DEST|DIGG',fnAlgoTmpMWD);
            hw.runScript(fnAlgoTmpMWD);
            hw.shadowUpdate();
            calibPassed = 1;
        else
            fprintff('[x] geom calib failed[e=%g]\n',results.geomErr);
        end
        if(runParams.uniformProjectionDFZ)
            Calibration.aux.setLaserProjectionUniformity(hw,false);
        end
        
    else
        fprintff('[?] skipped\n');
    end
end
function [results] = calibrateROI(hw, runParams, calibParams, results,fw,fnCalib, fprintff, t)
    fprintff('[-] Calibrating ROI... \n');
    if (runParams.ROI)
%         d = hw.getFrame(10);
%         roiRegs = Calibration.roi.runROICalib(d,calibParams);
        regs = fw.get(); % run bootcalcs
        %% Get spherical of both directions:
        r = Calibration.RegState(hw);
        r.add('DIGGsphericalEn'    ,true     );
        r.set();
        hw.cmd('iwb e2 06 01 00'); % Remove bias
        Calibration.aux.CBTools.showImageRequestDialog(hw,1,[],'Please Make Sure Borders Are Bright');
        [imU,imD]=Calibration.dataDelay.getScanDirImgs(hw);
        r.reset();
        hw.cmd('iwb e2 06 01 70'); % Return bias
        
        [roiRegs] = Calibration.roi.calibROI(imU,imD,regs,calibParams);
        fw.setRegs(roiRegs, fnCalib);
        fw.get(); % run bootcalcs
        fnAlgoTmpMWD =  fullfile(runParams.internalFolder,filesep,'algoROICalib.txt');
        fw.genMWDcmd('DEST|DIGG',fnAlgoTmpMWD);
        hw.runScript(fnAlgoTmpMWD);
        hw.shadowUpdate();
        fprintff('[v] Done(%ds)\n',round(toc(t)));
        
        FE = [];
        if calibParams.fovExpander.valid
            FE = calibParams.fovExpander.table;
        end
        fovData = Calibration.validation.calculateFOV(imU,imD,regs,FE);
        fprintff('Mirror opening angles slow and fast:      [%2.3g,%2.3g] degrees.\n',fovData.mirror.minMaxAngX);
        fprintff('                                          [%2.3g,%2.3g] degrees.\n',fovData.mirror.minMaxAngY);
        fprintff('Laser opening angles up slow and fast:    [%2.3g,%2.3g] degrees.\n',fovData.laser.minMaxAngXup);
        fprintff('                                          [%2.3g,%2.3g] degrees.\n',fovData.laser.minMaxAngYup);
        fprintff('Laser opening angles down slow and fast:  [%2.3g,%2.3g] degrees.\n',fovData.laser.minMaxAngXdown);
        fprintff('                                          [%2.3g,%2.3g] degrees.\n',fovData.laser.minMaxAngYdown);
         
        
    else
        fprintff('[?] skipped\n');
    end
end
function [results,luts] = fixAng2XYBugWithUndist(hw, runParams, calibParams, results,fw,fnCalib, fprintff, t)
    fprintff('[-] Fixing ang2xy using undist table...\n');
    if(runParams.undist)
        [udistlUT.FRMW.undistModel,udistRegs,results.maxPixelDisplacement] = Calibration.Undist.calibUndistAng2xyBugFix(fw,calibParams);
        udistRegs.DIGG.undistBypass = false;
        fw.setRegs(udistRegs,fnCalib);
        fw.setLut(udistlUT);
        [~,luts]=fw.get();
        if(results.maxPixelDisplacement<calibParams.errRange.maxPixelDisplacement(2))
            fprintff('[v] undist calib passed[e=%g]\n',results.maxPixelDisplacement);
        else
            fprintff('[x] undist calib failed[e=%g]\n',results.maxPixelDisplacement);
            
        end
        ttt=[tempname '.txt'];
        fw.genMWDcmd('DIGGundist_',ttt);
        hw.runScript(ttt);
        hw.shadowUpdate();
        fprintff('[v] Done(%ds)\n',round(toc(t)));
    else
        fprintff('[?] skipped\n');
        results.maxPixelDisplacement=inf;
    end
end
function writeVersionAndIntrinsics(verValue,fw,fnCalib)
    regs = fw.get();
    intregs.DIGG.spare=zeros(1,8,'uint32');
    intregs.DIGG.spare(1)=verValue;
    intregs.DIGG.spare(2)=typecast(single(regs.FRMW.xfov),'uint32');
    intregs.DIGG.spare(3)=typecast(single(regs.FRMW.yfov),'uint32');
    intregs.DIGG.spare(4)=typecast(single(regs.FRMW.laserangleH),'uint32');
    intregs.DIGG.spare(5)=typecast(single(regs.FRMW.laserangleV),'uint32');
    intregs.DIGG.spare(6)=verValue; %config version
    intregs.DIGG.spare(7)=uint32(regs.FRMW.marginL)*2^16 + uint32(regs.FRMW.marginR);
    intregs.DIGG.spare(8)=uint32(regs.FRMW.marginT)*2^16 + uint32(regs.FRMW.marginB);
    fw.setRegs(intregs,fnCalib);
    fw.get();
end
function score = mergeScores(results,runParams,calibParams,fprintff)
    f = fieldnames(results);
    scores=zeros(length(f),1);
    for i = 1:length(f)
        scores(i)=100-round(min(1,max(0,(results.(f{i})-calibParams.errRange.(f{i})(1))/diff(calibParams.errRange.(f{i}))))*99);
    end
    score = min(scores);
    
    
    if(runParams.verbose)
        for i = 1:length(f)
            s04=floor((scores(i)-1)/100*5);
            asciibar = sprintf('|%s#%s|',repmat('-',1,s04),repmat('-',1,4-s04));
            ll=fprintff('% 10s: %s %g\n',f{i},asciibar,results.(f{i}));
        end
        fprintff('%s\n',repmat('-',1,ll));
        s04=floor((score-1)/100*5);
        asciibar = sprintf('|%s#%s|',repmat('-',1,s04),repmat('-',1,4-s04));
        fprintff('% 10s: %s %g\n','score',asciibar,score);
        
    end
end

function burn2Device(hw,score,runParams,calibParams,fprintff,t)
    
    
    doCalibBurn = false;
    fprintff('[!] setting burn calibration...');
    if(runParams.burnCalibrationToDevice)
        if(score>=calibParams.passScore)
            doCalibBurn=true;
            fprintff('Done(%ds)\n',round(toc(t)));
        else
            fprintff('skiped, score too low(%d)\n',score);
        end
    else
        fprintff('skiped\n');
    end
    
    doConfigBurn = false;
    fprintff('[!] setting burn configuration...');
    if(runParams.burnConfigurationToDevice)
        doConfigBurn=true;
        fprintff('Done(%ds)\n',round(toc(t)));
    else
        fprintff('skiped\n');
    end
    
    fprintff('[!] burning...');
    hw.burn2device(runParams.outputFolder,doCalibBurn,doConfigBurn);
    fprintff('Done(%ds)\n',round(toc(t)));
end
function res = noCalibrations(runParams)
    res = ~(runParams.DSM || runParams.gamma || runParams.dataDelay || runParams.ROI || runParams.DFZ || runParams.undist);
end