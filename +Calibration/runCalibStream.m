function  [calibPassed] = runCalibStream(runParamsFn,calibParamsFn, fprintff,spark)
       
    t=tic;
    score=0;
    results = struct;
    if(~exist('fprintff','var'))
        fprintff=@(varargin) fprintf(varargin{:});
    end
    if(~exist('spark','var'))
        spark=[];
    end

    write2spark = ~isempty(spark);
    
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
    fw.get();%run autogen
    fprintff('Done(%ds)\n',round(toc(t)));
    
    %% Load hw interface
    hw = loadHWInterface(runParams,fw,fprintff,t);
    fprintff('%-15s %8s\n','serial',hw.getSerial());
    % Verify unit's configuration version
    verValue = getVersion(hw,runParams);  
    
    %% Update init configuration
    updateInitConfiguration(hw,fw,fnCalib,runParams,calibParams);
    %% Start stream to load the configuration
    fprintff('Opening stream...');
    hw.startStream();
    fprintff('Done(%ds)\n',round(toc(t)));
    %% Init hw configuration
    initConfiguration(hw,fw,runParams,fprintff,t);

    %% Set coarse DSM values 
    calibrateCoarseDSM(hw, runParams, calibParams, fprintff,t);
    
    %% Get a frame to see that hwinterface works.
    fprintff('Capturing frame...');
    hw.getFrame();
    fprintff('Done(%ds)\n',round(toc(t)));
    %% ::calibrate delays::
    [results,calibPassed] = calibrateDelays(hw, runParams, calibParams, results, fw, fnCalib, fprintff);
    if ~calibPassed
        return;
    end
    
    %% ::dsm calib::
    calibrateDSM(hw, fw, runParams, calibParams,results,fnCalib, fprintff,t);

   %% Validate spherical fill rate
   [results,calibPassed] = validateCoverage(hw,1, runParams, calibParams,results, fprintff);
   if ~calibPassed
       return 
    end
    %% ::gamma:: 
	results = calibrateDiggGamma(runParams, calibParams, results, fprintff, t);
	calibrateJfilGamma(fw, calibParams,runParams,fnCalib,fprintff);

    
    %% ::DFZ::  Apply DFZ result if passed (It affects next calibration stages)
    [results,calibPassed] = calibrateDFZ(hw, runParams, calibParams, results,fw,fnCalib, fprintff, t);
    if ~calibPassed
       return 
    end

    
    %% ::roi::
    [results] = calibrateROI(hw, runParams, calibParams, results,fw,fnCalib, fprintff, t);
    
    %% write version+intrinsics
    writeVersionAndIntrinsics(verValue,fw,fnCalib);
    
    %% ::Fix ang2xy Bug using undistort table::
    [results,luts] = fixAng2XYBugWithUndist(hw, runParams, calibParams, results,fw, fnCalib, fprintff, t);
    % Coverage within ROI 
    [results,calibPassed] = validateCoverage(hw,0, runParams, calibParams,results, fprintff);
    if ~calibPassed
       return 
    end
    %% Print image final fov
    [results,calibPassed] = Calibration.aux.calcImFov(fw,results,calibParams,fprintff);
    if ~calibPassed
       return 
    end
    % Update fnCalin and undist lut in output dir
    fw.writeUpdated(fnCalib);
    io.writeBin(fnUndsitLut,luts.FRMW.undistModel);
    Calibration.aux.logResults(results,runParams);
    Calibration.aux.writeResults2Spark(results,spark,calibParams.errRange,write2spark);
    %% merge all scores outputs
    calibPassed = Calibration.aux.mergeScores(results,calibParams.errRange,fprintff);
    
    fprintff('[!] calibration ended - ');
    if(calibPassed==0)
        fprintff('FAILED.\n');
    else
        fprintff('PASSED.\n');
    end
    
    %% Burn 2 device
    burn2Device(hw,calibPassed,runParams,calibParams,fprintff,t);
    
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
    initFldr = fullfile(fileparts(mfilename('fullpath')),'initConfigCalib');
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
function updateInitConfiguration(hw,fw,fnCalib,runParams,calibParams)
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
    currregs.GNRL.imgHsize = uint16(calibParams.gnrl.internalImSize(2));
    currregs.GNRL.imgVsize = uint16(calibParams.gnrl.internalImSize(1));
    currregs.PCKR.padding = uint32(prod(calibParams.gnrl.externalImSize)-prod(calibParams.gnrl.internalImSize));
    fw.setRegs(currregs,fnCalib);
    fw.get();
    
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
        hw.setSize();
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
        [delayRegs,delayCalibResults]=Calibration.dataDelay.calibrate(hw,calibParams.dataDelay,fprintff,runParams);
        
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
        Calibration.aux.calibCoarseDSM(hw,calibParams,runParams);
        fprintff('[v] Done(%d)\n',round(toc(t)));
    else
        fprintff('[?] skipped\n');
    end
end
function [results,calibPassed] = validateCoverage(hw,sphericalEn, runParams, calibParams, results, fprintff)
    calibPassed = 1;
    if runParams.validation
        if sphericalEn 
            sphericalmode = 'Spherical Enable';
            fname = strcat('irCoverage','SpEn');
            fnameStd = strcat('stdIrCoverage','SpEn');
        else
            sphericalmode = 'spherical disable';
            fname = strcat('irCoverage','SpDis');
            fnameStd = strcat('stdIrCoverage','SpDis');
        end
        
        %test coverage
        [~, covResults] = Calibration.validation.validateCoverage(hw,sphericalEn);
        % save prob figure
        ff = Calibration.aux.invisibleFigure;
        imagesc(covResults.probIm);
        
        title(sprintf('Coverage Map %s',sphericalmode)); colormap jet;colorbar;
        Calibration.aux.saveFigureAsImage(ff,runParams,'Validation',sprintf('Coverage Map %s',sphericalmode));

        calibPassed = covResults.irCoverage <= calibParams.errRange.(fname)(2) && ...
            covResults.irCoverage >= calibParams.errRange.(fname)(1);
        
        
        if calibPassed
            fprintff('[v] ir coverage %s passed[e=%g]\n',sphericalmode,covResults.irCoverage);
        else
            fprintff('[x] ir coverage %s passed[e=%g]\n',sphericalmode,covResults.irCoverage);
        end
        if sphericalEn
            results.(fname) = covResults.irCoverage;
            results.(fnameStd) = covResults.stdIrCoverage; 
        else
            results.(fname) = covResults.irCoverage;
            results.(fnameStd) = covResults.stdIrCoverage; 
        end
    end
end
function calibrateDSM(hw,fw, runParams, calibParams,results, fnCalib, fprintff, t)
    fprintff('[-] DSM calibration...\n');
    if(runParams.DSM)
        
        dsmregs = Calibration.aux.calibDSM(hw,calibParams,fprintff,runParams);
        fw.setRegs(dsmregs,fnCalib);
        fprintff('[v] Done(%d)\n',round(toc(t)));
    else
        fprintff('[?] skipped\n');
    end
    
end

function calibrateJfilGamma(fw, calibParams,runParams,fnCalib,fprintff)
    fprintff('[-] Jfil gamma...\n');
    if (runParams.gamma)
        irInnerRange = calibParams.gnrl.irInnerRange;
        irOuterRange = calibParams.gnrl.irOuterRange;
        regs = fw.get();
        newGammaScale = int16([regs.JFIL.gammaScale(1),diff(irOuterRange)/diff(irInnerRange)*1024]);
        newGammaShift = int16([regs.JFIL.gammaShift(1),irOuterRange(1) - newGammaScale(2)*irInnerRange(1)/1024]);
        gammaRegs.JFIL.gammaScale = newGammaScale;
        gammaRegs.JFIL.gammaShift = newGammaShift;
        fw.setRegs(gammaRegs,fnCalib);
        fprintff('[v] Done\n');
    else
        fprintff('[?] skipped\n');
    end

end

function results = calibrateDiggGamma(runParams, calibParams, results, fprintff, t)
    fprintff('[-] Digg gamma...\n');
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
function [results,calibPassed] = calibrateDFZ(hw, runParams, calibParams, results, fw, fnCalib, fprintff, t)

    calibPassed = 1;
    fprintff('[-] FOV, System Delay, Zenith and Distortion calibration...\n');
    if(runParams.DFZ)
        calibPassed = 0;
        if(runParams.uniformProjectionDFZ)
            Calibration.aux.setLaserProjectionUniformity(hw,true);
        end
        [regs,luts]=fw.get();
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
        x0 = double([dfzRegs.FRMW.xfov dfzRegs.FRMW.yfov dfzRegs.DEST.txFRQpd(1) dfzRegs.FRMW.laserangleH dfzRegs.FRMW.laserangleV]);
        [~,results.geomErrExtraImages] = Calibration.aux.calibDFZ(d(4:end),regs,calibParams,fprintff,0,1,x0);
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
function imNoise = collectNoiseIm(hw)
        hw.cmd('iwb e2 06 01 00'); % Remove bias
        hw.cmd('iwb e2 08 01 0'); % modulation amp is 0
        hw.cmd('iwb e2 03 01 10');% internal modulation (from register)
        pause(0.1);
        imNoise = double(hw.getFrame(10).i)/255;
        hw.cmd('iwb e2 03 01 90');% 
        hw.cmd('iwb e2 06 01 70'); % Return bias
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
        fprintff('[-] Collecting up/down frames... ');
        Calibration.aux.CBTools.showImageRequestDialog(hw,1,[],'Make sure image is bright');
        [imUbias,imDbias]=Calibration.dataDelay.getScanDirImgs(hw,1);
        pause(0.1);
        fprintff('Done.\n');
        % Remove modulation as well to get a noise image
        
        imNoise = collectNoiseIm(hw);

        % Ambient value - Mean of the center 21x21 (arbitrary) patch in the noise image.
        results.ambVal = mean(vec(imNoise(size(imNoise,1)/2-10:size(imNoise,1)/2+10, size(imNoise,2)/2-10:size(imNoise,2)/2+10)));
        r.reset();
        
        
        [roiRegs] = Calibration.roi.calibROI(imUbias,imDbias,imNoise,regs,calibParams,runParams);
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
        fovData = Calibration.validation.calculateFOV(imUbias,imDbias,imNoise,regs,FE);
        results.upDownFovDiff = sum(abs(fovData.laser.minMaxAngYup-fovData.laser.minMaxAngYdown));
        fprintff('Mirror opening angles slow and fast:      [%2.3g,%2.3g] degrees.\n',fovData.mirror.minMaxAngX);
        fprintff('                                          [%2.3g,%2.3g] degrees.\n',fovData.mirror.minMaxAngY);
        fprintff('Laser opening angles slow (up):           [%2.3g,%2.3g] degrees.\n',fovData.laser.minMaxAngXup);
        fprintff('Laser opening angles slow (down):         [%2.3g,%2.3g] degrees.\n',fovData.laser.minMaxAngXdown);
        fprintff('Laser opening angles fast (up):           [%2.3g,%2.3g] degrees.\n',fovData.laser.minMaxAngYup);
        fprintff('Laser opening angles fast (down):         [%2.3g,%2.3g] degrees.\n',fovData.laser.minMaxAngYdown);
        fprintff('Laser up/down fov diff:  %2.3g degrees.\n',results.upDownFovDiff);
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
    intregs.JFIL.spare=zeros(1,8,'uint32');
    [zoCol,zoRow] = Calibration.aux.zoLoc(fw);
    intregs.JFIL.spare(1)=uint32(zoRow)*2^16 + uint32(zoCol);
    fw.setRegs(intregs,fnCalib);
    fw.get();
end



function burn2Device(hw,calibPassed,runParams,calibParams,fprintff,t)
    
    
    doCalibBurn = false;
    fprintff('[!] setting burn calibration...');
    if(runParams.burnCalibrationToDevice)
        if(calibPassed)
            doCalibBurn=true;
            fprintff('Done(%ds)\n',round(toc(t)));
        else
            fprintff('skiped, failed calibration.\n');
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