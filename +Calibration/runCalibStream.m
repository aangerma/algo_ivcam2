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
    
    %% Init hw configuration
    initConfiguration(hw,fw,runParams,calibParams,fprintff,t);
    
    %% Get a single frame to see that the unit functions
    fprintff('opening stream...');
    hw.getFrame();
    fprintff('Done(%ds)\n',round(toc(t)));
     
    %% Set coarse DSM values 
    coarseDSMRegs = calibrateCoarseDSM(hw, runParams, calibParams, fprintff,t);

    %% ::calibrate delays::
    [results,calibPassed] = calibrateDelays(hw, runParams, calibParams, results, fw, fnCalib, fprintff);
    if ~calibPassed
        return;
    end
    
    %% ::dsm calib::
    dsmRegs = calibrateDSM(hw, runParams, calibParams, fprintff,t);
    fw.setRegs(dsmRegs,fnCalib);
    regs=fw.get();
   
    %% ::gamma:: 
    results = calibrateGamma(runParams, calibParams, results, fprintff, t);
    
    %% ::DFZ::  Apply DFZ result if passed (It affects next calibration stages)
    [results,calibPassed] = calibrateDFZ(hw, regs, runParams, calibParams, results,fw,fnCalib, fprintff, t);
    if ~calibPassed
       return 
    end

    
    %% ::roi::
    [results,regs] = calibrateROI(hw, regs, runParams, calibParams, results,fw,fnCalib, fprintff, t);
    
    %% ::Fix ang2xy Bug using undistort table::
    [results,luts] = fixAng2XYBugWithUndist(hw, regs, runParams, calibParams, results,fw, fprintff, t);
    
%     %% ::validation::
%     fprintff('[-] Validating...\n');
%     %validate
%     if(runParams.DFZ && runParams.validation)
%         d=showImageRequestDialog(hw,1,diag([.7 .7 1]));
%         
%         [~,results.geomErrVal] = Calibration.aux.calibDFZ(d,regs,verbose,true);
%         if(results.geomErrVal<calibParams.errRange.geomErrVal(2))
%             fprintff('[v] geom valid passed[e=%g]\n',results.geomErrVal);
%         else
%             fprintff('[x] geom valid failed[e=%g]\n',results.geomErrVal);
%             
%         end
%     else
%         fprintff('[?] skipped\n');
%     end
    
    %% write version+intrinsics
    writeVersionAndIntrinsics(verValue,regs,fw,fnCalib);
    
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
    if runParams.replayMode
        runParams.internalFolder = tempname;
    else
        runParams.internalFolder = fullfile(runParams.outputFolder,'AlgoInternal');  
        mkdirSafe(runParams.outputFolder);
    end
    mkdirSafe(runParams.internalFolder);
    fnCalib     = fullfile(runParams.internalFolder,'calib.csv');
    fnUndsitLut = fullfile(runParams.internalFolder,'FRMWundistModel.bin32');
    initFldr = fullfile(fileparts(mfilename('fullpath')),'initScript');
    copyfile(fullfile(initFldr,'*.csv'), runParams.internalFolder)
    
end

function hw = loadHWInterface(runParams,fw,fprintff,t)
    fprintff('Loading HW interface...');
    hwRecFile = fullfile(runParams.outputFolder);
    if runParams.replayMode
        if(exist(hwRecFile,'file'))
            % Use recorded session
            hw=HWinterfaceFile(hwRecFile);
            fprintff('Loading recorded capture(%s)\n',hwRecFile);
            
        else
            error('no file found in %s\n',hwRecFile)
        end
    else
        hw=HWinterface(fw,fullfile(hwRecFile,'sessionRecord.mat'));
        
    end
    fprintff('Done(%ds)\n',round(toc(t)));
end

function verValue = getVersion(hw,runParams)
    verValue = typecast(uint8([floor(100*mod(runParams.version,1)) floor(runParams.version) 0 0]),'uint32');
    
    unitConfigVersion=hw.read('DIGGspare_005');
    if(unitConfigVersion~=verValue)
        warning('incompatible configuration versions!');
    end
end
function initConfiguration(hw,fw,runParams,calibParams,fprintff,t)
    fprintff('init hw configuration...');
    if(runParams.init)
        fnAlgoInitMWD  =  fullfile(runParams.internalFolder,filesep,'algoInit.txt');
        fw.genMWDcmd('^(?!MTLB|EPTG|FRMW|DSM.*$).*',fnAlgoInitMWD);
        hw.runPresetScript('maReset');
        pause(0.1);
        hw.runScript(fnAlgoInitMWD);
        pause(0.1);
        hw.runPresetScript('maRestart');
        pause(0.1);
        
        Calibration.dataDelay.setAbsDelay(hw,calibParams.dataDelay.slowDelayInitVal,false);
        
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
function dsmregs = calibrateCoarseDSM(hw, runParams, calibParams, fprintff, t)
    % Set a DSM value that makes the valid area of the image in spherical
    % mode to be above a certain threshold.
    fprintff('[-] Coarse DSM calibration...\n');
    if(runParams.DSM)
        dsmregs = Calibration.aux.calibCoarseDSM(hw,calibParams,runParams.verbose);
        fprintff('[v] Done(%d)\n',round(toc(t)));
    else
        dsmregs = [];
        fprintff('[?] skipped\n');
    end
end
function dsmregs = calibrateDSM(hw, runParams, calibParams, fprintff, t)
    fprintff('[-] DSM calibration...\n');
    if(runParams.DSM)
        dsmregs = Calibration.aux.calibDSM(hw,calibParams,fprintff,runParams.verbose);
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
function [results,calibPassed,regs,luts] = calibrateDFZ(hw, regs, runParams, calibParams, results, fw, fnCalib, fprintff, t)
    calibPassed = -1;
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
        d(6)=Calibration.aux.CBTools.showImageRequestDialog(hw,2,diag([2 2 1]));
        
        
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
function [results,regs] = calibrateROI(hw, regs, runParams, calibParams, results,fw,fnCalib, fprintff, t)
    fprintff('[-] Calibrating ROI...\n');
    if (runParams.ROI)
        d = hw.getFrame(10);
        roiRegs = Calibration.roi.runROICalib(d,calibParams);
        fw.setRegs(roiRegs, fnCalib);
        regs = fw.get(); % run bootcalcs
        fnAlgoTmpMWD =  fullfile(runParams.internalFolder,filesep,'algoROICalib.txt');
        fw.genMWDcmd('DEST|DIGG',fnAlgoTmpMWD);
        hw.runScript(fnAlgoTmpMWD);
        hw.shadowUpdate();
        d = hw.getFrame(10);
        roiRegsVal = Calibration.roi.runROICalib(d,calibParams);
        mr = roiRegsVal.FRMW;
        valSumMargins = double(mr.marginL + mr.marginR + mr.marginT + mr.marginB);
        %     results.roiVal = valSumMargins;
        if (valSumMargins ~= 0)
            fprintff('warning: Invalid pixels after ROI calibration\n');
        end
        fprintff('[v] Done(%ds)\n',round(toc(t)));
    else
        fprintff('[?] skipped\n');
    end
end
function [results,luts] = fixAng2XYBugWithUndist(hw, regs, runParams, calibParams, results,fw, fprintff, t)
    fprintff('[-] Fixing ang2xy using undist table...\n');
    if(runParams.undist)
        [undistlut.FRMW.undistModel, results.maxPixelDisplacement] = Calibration.Undist.calibUndistAng2xyBugFix(regs,runParams.verbose);
        fw.setLut(undistlut);
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
function writeVersionAndIntrinsics(verValue,regs,fw,fnCalib)
    intregs.DIGG.spare=zeros(1,8,'uint32');
    intregs.DIGG.spare(1)=verValue;
    intregs.DIGG.spare(2)=typecast(single(regs.FRMW.xfov),'uint32');
    intregs.DIGG.spare(3)=typecast(single(regs.FRMW.yfov),'uint32');
    intregs.DIGG.spare(4)=typecast(single(regs.FRMW.laserangleH),'uint32');
    intregs.DIGG.spare(5)=typecast(single(regs.FRMW.laserangleV),'uint32');
    intregs.DIGG.spare(6)=verValue; %config version
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
    
    fprintff('[!] burnning...');
    hw.burn2device(runParams.outputFolder,doCalibBurn,doConfigBurn);
    fprintff('Done(%ds)\n',round(toc(t)));
end
function res = noCalibrations(runParams)
    res = ~(runParams.DSM || runParams.gamma || runParams.dataDelay || runParams.ROI || runParams.DFZ || runParams.undist);
end