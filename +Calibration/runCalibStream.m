function  [calibPassed,score] = runCalibStream(runParamsFn,calibParamsFn, fprintff)
    
    
    t=tic;
    score=0;
    
    
    runParams=xml2structWrapper(runParamsFn);
    if(~exist('calibParamsFn','var') || isempty(calibParamsFn))
        %% ::load default caliration configuration
        calibParamsFn='calibParams.xml';
    end
    calibParams = xml2structWrapper(calibParamsFn);
    if(~exist('fprintff','var'))
        fprintff=@(varargin) fprintf(varargin{:});
    end
    verbose = runParams.verbose;
    
    
    
    
    
    results = struct;
    
    
    
    %% :: file names
    runParams.internalFolder = fullfile(runParams.outputFolder,filesep,'AlgoInternal');
    
    
    mkdirSafe(runParams.outputFolder);
    mkdirSafe(runParams.internalFolder);
    
    
    fnCalib     = fullfile(runParams.internalFolder,filesep,'calib.csv');
    fnUndsitLut = fullfile(runParams.internalFolder,filesep,'FRMWundistModel.bin32');
    initFldr = fullfile(fileparts(mfilename('fullpath')),'initScript');
    copyfile(fullfile(initFldr,filesep,'*.csv'), runParams.internalFolder)
    
    fprintff('Starting calibration:\n');
    fprintff('%-15s %s\n','stated at',datestr(now));
    fprintff('%-15s %5.2f\n','version',runParams.version);
    %% ::Init fw
    fprintff('Loading Firmware...');
    fw = Pipe.loadFirmware(runParams.internalFolder);
    fprintff('Done(%ds)\n',round(toc(t)));
    
    fprintff('Loading HW interface...');
    hwRecFile = fullfile(fileparts(runParamsFn),filesep,'sessionRecord.mat');
    if(exist(hwRecFile,'file'))
        %run recorded session
        hw=HWinterfaceFile(hwRecFile);
        fprintf('Loading recorded capture(%s)\n',hwRecFile);
    else
        hw=HWinterface(fw,hwRecFile);
    end
    fprintff('Done(%ds)\n',round(toc(t)));
    [regs,luts]=fw.get();%run autogen
    
    %verify unit's configuration version
    verValue = typecast(uint8([floor(100*mod(runParams.version,1)) floor(runParams.version) 0 0]),'uint32');
    
    unitConfigVersion=hw.read('DIGGspare_005');
    if(unitConfigVersion~=verValue)
        warning('incompatible configuration versions!');
    end
    
    
    % hw.runPresetScript('systemConfig');
    fprintff('init...');
    if(runParams.init)
        fnAlgoInitMWD  =  fullfile(runParams.internalFolder,filesep,'algoInit.txt');
        fw.genMWDcmd('^(?!MTLB|EPTG|FRMW.*$).*',fnAlgoInitMWD);
        hw.runPresetScript('maReset');
        pause(0.1);
        hw.runScript(fnAlgoInitMWD);
        pause(0.1);
        % mwd a0010104 a0010108 19DDDDFD // Force disables JFIL
        hw.runPresetScript('maRestart');
        pause(0.1);
        
        Calibration.dataDelay.setAbsDelay(hw,calibParams.dataDelay.slowDelayInitVal,false);
        
        hw.shadowUpdate();
        fprintff('Done(%ds)\n',round(toc(t)));
    else
        fprintff('skipped\n');
    end
    
    fprintff('opening stream...');
    hw.getFrame();
    
    % [capturingFailure, fixedDelay] = checkAndFixAbsDelay(hw,fprintff);
    % if capturingFailure
    %         return;
    % end
    % if fixedDelay
    %     calibParams.dataDelay.slowDelayInitVal = fixedDelay;
    % end
    fprintff('Done(%ds)\n',round(toc(t)));
    
    
    % hw.runPresetScript('startStream');
    
    %% ::calibrate delays::
    fprintff('[-] Depth and IR delay calibration...\n');
    
    if(runParams.dataDelay)
        
        showImageRequestDialog(hw,1,diag([.8 .8 1]));
        [delayRegs,okZ,okIR]=Calibration.dataDelay.calibrate(hw,calibParams.dataDelay,verbose);
        results.delayS=(1-okIR);
        results.delayF=(1-okZ);
        if(okIR)
            fprintff('[v] ir calib passed[e=%g]\n',results.delayS);
        else
            fprintff('[x] ir calib failed[e=%g]\n',results.delayS);
            calibPassed = 0;
            return;
        end
        
        if(okZ)
            fprintff('[v] depth calib passed[e=%g]\n',results.delayF);
        else
            fprintff('[x] depth calib failed[e=%g]\n',results.delayF);
            calibPassed = 0;
            return;
        end
        
        fw.setRegs(delayRegs,fnCalib);
        
    else
        fprintff('skipped\n');
    end
    %% ::dsm calib::
    fprintff('[-] DSM calibration...\n');
    if(runParams.DSM)
        dsmregs = Calibration.aux.calibDSM(hw,calibParams,verbose);
        fw.setRegs(dsmregs,fnCalib);
        fprintff('[v] Done(%d)\n',round(toc(t)));
    else
        fprintff('[?] skipped\n');
    end
    %% ::gamma::
    
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
    %% ::RX Delay::
    % rxregs.DEST.rxPWRpd = single(calibParams.rx); %pass gamma regs when available.
    %fw.setRegs(rxregs,fnCalib);
    %% ::thermal::
    % thermalRegs=Calibration.thermal.setThermalRegs(calibParams.thermal);
    % fw.setRegs(thermalRegs,fnCalib);
    
    %% ::DFZ::
    
    fprintff('[-] FOV, System Delay, Zenith and Distortion calibration...\n');
    if(runParams.DFZ)
        if(runParams.uniformProjectionDFZ)
            Calibration.aux.setLaserProjectionUniformity(hw,true);
        end
        regs.DEST.depthAsRange=true;regs.DIGG.sphericalEn=true;
        r=Calibration.RegState(hw);
        
        r.add('JFILinvBypass',true);
        r.add('DESTdepthAsRange',true);
        r.add('DIGGsphericalEn',true);
        r.set();
        
        
        d(1)=showImageRequestDialog(hw,1,diag([.7 .7 1]));
        d(2)=showImageRequestDialog(hw,1,diag([.6 .6 1]));
        d(3)=showImageRequestDialog(hw,1,diag([.5 .5 1]));
        d(4)=showImageRequestDialog(hw,1,[.5 0 .1;0 .5 0; 0.2 0 1]);
        d(5)=showImageRequestDialog(hw,1,[.5 0 -.1;0 .5 0; -0.2 0 1]);
        d(6)=showImageRequestDialog(hw,2,diag([2 2 1]));
        
        
        % dodluts=struct;
        [dodregs,results.geomErr] = Calibration.aux.calibDFZ(d(1:3),regs,verbose);
        r.reset();
        
        fw.setRegs(dodregs,fnCalib);
        if(results.geomErr<calibParams.errRange.geomErr(2))
            fprintff('[v] geom calib passed[e=%g]\n',results.geomErr);
            fnAlgoTmpMWD =  fullfile(runParams.internalFolder,filesep,'algoValidCalib.txt');
            [regs,luts]=fw.get();%run autogen
            fw.genMWDcmd('DEST|DIGG',fnAlgoTmpMWD);
            hw.runScript(fnAlgoTmpMWD);
            hw.shadowUpdate();
        else
            fprintff('[x] geom calib failed[e=%g]\n',results.geomErr);
        end
        Calibration.aux.setLaserProjectionUniformity(hw,false);
        
    else
        fprintff('[?] skipped\n');
    end
    
    
    %% ::roi::
    fprintff('[-] Calibrating ROI...\n');
    % params.roi = true;
    if (runParams.ROI)
        d = hw.getFrame(10);
        [regs,luts]=fw.get();
        
        
        roiRegs = Calibration.roi.runROICalib(d,true);
        fw.setRegs(roiRegs, fnCalib);
        regs = fw.get(); % run bootcalcs
        fnAlgoTmpMWD =  fullfile(runParams.internalFolder,filesep,'algoROICalib.txt');
        fw.genMWDcmd('DEST|DIGG',fnAlgoTmpMWD);
        hw.runScript(fnAlgoTmpMWD);
        hw.shadowUpdate();
        d = hw.getFrame(10);
        roiRegsVal = Calibration.roi.runROICalib(d,false);
        mr = roiRegsVal.FRMW;
        valSumMargins = double(mr.marginL + mr.marginR + mr.marginT + mr.marginB);
        %     results.roiVal = valSumMargins;
        if (valSumMargins ~= 0)
            fprintff('warning: Invalid pixels after ROI calibration');
        end
        fprintff('[v] Done(%ds)\n',round(toc(t)));
    else
        fprintff('[?] skipped\n');
    end
    
    %%apply txLUT
    % % % fprintff('generating TX power LUT table...');
    % % % regs = fw.get(); % run bootcalcs
    % % % txLUTregs=Calibration.txPWR.genTXlut(hw,regs.FRMW.yfov,regs.FRMW.marginB,regs.FRMW.marginT);
    % % % fw.setRegs(txLUTregs,fnCalib);
    % % % ttt=[tempname '.txt'];
    % % % fw.genMWDcmd('DESTtxPWRpd_',ttt);
    % % % hw.runScript(ttt);
    % % % fprintff('done\n');
    
    
    
    %% ::Fix ang2xy Bug using undistort table::
    fprintff('[-] Fixing ang2xy using undist table...\n');
    if(runParams.undist)
        % % %     undistlut.FRMW.undistModel=zeros(2048,1,'uint32');
        % % %      fw.setLut(undistlut);
        [undistlut.FRMW.undistModel, results.maxPixelDisplacement] = Calibration.Undist.calibUndistAng2xyBugFix(regs,verbose);
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
    
    %% ::validation::
    fprintff('[-] Validating...\n');
    %validate
    if(runParams.DFZ && runParams.validation)
        d=showImageRequestDialog(hw,1,diag([.7 .7 1]));
        
        [~,results.geomErrVal] = Calibration.aux.calibDFZ(d,regs,verbose,true);
        if(results.geomErrVal<calibParams.errRange.geomErrVal(2))
            fprintff('[v] geom valid passed[e=%g]\n',results.geomErrVal);
        else
            fprintff('[x] geom valid failed[e=%g]\n',results.geomErrVal);
            
        end
    else
        fprintff('[?] skipped\n');
    end
    
    %% write version+intrinsics
    
    intregs.DIGG.spare=zeros(1,8,'uint32');
    intregs.DIGG.spare(1)=verValue;
    intregs.DIGG.spare(2)=typecast(single(dodregs.FRMW.xfov),'uint32');
    intregs.DIGG.spare(3)=typecast(single(dodregs.FRMW.yfov),'uint32');
    intregs.DIGG.spare(4)=typecast(single(dodregs.FRMW.laserangleH),'uint32');
    intregs.DIGG.spare(5)=typecast(single(dodregs.FRMW.laserangleV),'uint32');
    intregs.DIGG.spare(6)=verValue; %config version
    fw.setRegs(intregs,fnCalib);
    fw.writeUpdated(fnCalib);
    fw.get();
    
    io.writeBin(fnUndsitLut,luts.FRMW.undistModel);
    
    
    
    
    
    
    
    
    
    
    
    %% merge all scores outputs
    
    f = fieldnames(results);
    scores=zeros(length(f),1);
    for i = 1:length(f)
        scores(i)=100-round(min(1,max(0,(results.(f{i})-calibParams.errRange.(f{i})(1))/diff(calibParams.errRange.(f{i}))))*99);
    end
    score = min(scores);
    
    
    if(verbose)
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
    
    
    fprintff('[!] calibration ended - ');
    if(score==0)
        fprintff('FAILED.\n');
    elseif(score<calibParams.passScore)
        fprintff('QUALITY FAILED.\n');
    else
        fprintff('PASSED.\n');
    end
    
    calibPassed = (score>=calibParams.passScore);
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
    
    fprintff('Calibration finished(%d)\n',round(toc(t)));
    
end





function raw=showImageRequestDialog(hw,figNum,tformData)
    persistent figImgs;
    figTitle = 'Please align image board to overlay';
    if(isempty(figImgs))
        bd = fullfile(fileparts(mfilename('fullpath')),filesep,'targets',filesep);
        figImgs{1} = imread([bd 'calibrationChart.png']);
        figImgs{2} = imread([bd 'fineCheckerboardA3.png']);
    end
    
    f=figure('NumberTitle','off','ToolBar','none','MenuBar','none','userdata',0,'KeyPressFcn',@(varargin) set(varargin{1},'userdata',1));
    a=axes('parent',f);
    maximizeFig(f);
    I = mean(figImgs{figNum},3);
    %%
    
    move2Ncoords = [2/size(I,2) 0 0 ; 0 2/size(I,1) 0; -1/size(I,2)-1 -1/size(I,1)-1 1];
    
    It= imwarp(I, projective2d(move2Ncoords*tformData'),'bicubic','fill',0,'OutputView',imref2d([480 640],[-1 1],[-1 1]));
    It = uint8(It.*permute([0 1 0],[3 1 2]));
    
    %%
    while(ishandle(f) && get(f,'userdata')==0)
        
        raw=hw.getFrame(-1);
        %recored stream
        if(all(raw.i(:)==0))
            break;
        end
        image(uint8(repmat(rot90(raw.i,2)*.8,1,1,3)+It*.25));
        axis(a,'image');
        axis(a,'off');
        title(figTitle);
        colormap(gray(256));
        drawnow;
    end
    close(f);
    
    raw=hw.getFrame(30);
    
    
    
end
