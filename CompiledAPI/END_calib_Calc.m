function [results ,luts] = END_calib_Calc(verValue,verValueFull,delayRegs, dsmregs,roiRegs,dfzRegs,results,fnCalib,calibParams)
% the function calcualte the undistored table based on the result from the DFZ and ROI then prepare calibration scripts  
% to burn into the eprom. later on the function will create calibration
% eprom table. the FW will process them and set the registers as needed. 
%
% inputs:
%   verValue     - just major version
%   verValueFull - full version
%   delayRegs    - output of the of IR/Z delay (the actual setting value as in setabsDelay fundtion)
%   dsmregs      - output of the DSM_Calib_Calc
%   roiRegs      - output of the ROI_Calib_Calc
%   dfzRegs      - output of the DFZ_Calib_Calc
%   results      - incrmental result of prev algo.
%   fnCalib      - base directory of calib/config files (calib.csv ,
%   config.csv , mode.csv)
%   calibParams  - calibration params.
%                                  
% output:
%   results - incrmntal result 
%   luts - undistort table.
%
    global g_output_dir g_debug_log_f g_verbose  g_save_input_flag  g_save_output_flag  g_dummy_output_flag g_fprintff; % g_regs g_luts;
    fprintff = g_fprintff;
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
    
    func_name = dbstack;
    func_name = func_name(1).name;
    % save Input
    if g_save_input_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, [func_name '_in.mat']);
        save(fn,'verValue','verValueFull','delayRegs', 'dsmregs' ,'roiRegs','dfzRegs','results','fnCalib' );
    end
    [results ,luts] = final_calib(verValue,verValueFull,delayRegs, dsmregs,roiRegs,dfzRegs,results,fnCalib, fprintff, calibParams);    % save output
    if g_save_output_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, [func_name '_out.mat']);
        save(fn,'results', 'luts');
    end

end

function [results ,luts] = final_calib(verValue,verValueFull,delayRegs, dsmregs,roiRegs,dfzRegs,results,fnCalib, fprintff, calibParams)
    t = tic;
    %% load inital FW.
%    fw = Pipe.loadFirmware(internalFolder);
    path = fileparts(fnCalib);
    if(isfile(fullfile(path , 'regsDefinitions.frmw')))
        fw = Pipe.loadFirmware(path,'tablesFolder',path); % incase of DLL assume table same folder as fnCalib
    else
        fw = Pipe.loadFirmware(path); % use default path of table folder
    end
    %% set regs from all algo calib
    fw.setRegs(dsmregs,  fnCalib); % DO NOT CHANGE THE ORDER OF THE CALLS TO setRegs
    fw.setRegs(delayRegs,fnCalib); 
    fw.setRegs(dfzRegs,  fnCalib);  
    fw.setRegs(roiRegs,  fnCalib);
    %% prepare spare register to store the fov. 
    writeVersionAndIntrinsics(verValue,verValueFull,fw,fnCalib,calibParams,fprintff);
    runParams.undist = true;
    [results,luts] = fixAng2XYBugWithUndist(runParams, calibParams, results,fw,fnCalib, fprintff, t);
    %% Print image final fov
    [results,calibPassed] = Calibration.aux.calcImFov(fw,results,calibParams,fprintff);
    path = fileparts(fnCalib);
    fnUndsitLut = fullfile(path,'FRMWundistModel.bin32');
    writeCalibRegsProps(fw,fnCalib);
    fw.writeUpdated(fnCalib);
    io.writeBin(fnUndsitLut,luts.FRMW.undistModel);
    oldFWVersion = false;
    fw.writeFirmwareFiles(path,oldFWVersion);
end

function writeVersionAndIntrinsics(verValue,verValueFull,fw,fnCalib,calibParams,fprintff)
    regs = fw.get();
    intregs.DIGG.spare=zeros(1,8,'uint32');
    intregs.DIGG.spare(1)=verValueFull;
    intregs.DIGG.spare(2)=typecast(single(regs.FRMW.xfov(1)),'uint32');
    intregs.DIGG.spare(3)=typecast(single(regs.FRMW.yfov(1)),'uint32');
    intregs.DIGG.spare(4)=typecast(single(regs.FRMW.laserangleH),'uint32');
    intregs.DIGG.spare(5)=typecast(single(regs.FRMW.laserangleV),'uint32');
    intregs.DIGG.spare(6)=verValue; %config version
    intregs.DIGG.spare(7)=uint32(regs.FRMW.calMarginL)*2^16 + uint32(regs.FRMW.calMarginR);
    intregs.DIGG.spare(8)=uint32(regs.FRMW.calMarginT)*2^16 + uint32(regs.FRMW.calMarginB);
    intregs.JFIL.spare=zeros(1,8,'uint32');
    %[zoCol,zoRow] = Calibration.aux.zoLoc(fw);
    intregs.JFIL.spare(1)=uint32(regs.FRMW.zoWorldRow(1))*2^16 + uint32(regs.FRMW.zoWorldCol(1));
    intregs.JFIL.spare(2)=typecast(regs.FRMW.dfzCalTmp,'uint32');
    fw.setRegs(intregs,fnCalib);
    fw.get();
    
    fprintff('Zero Order Pixel Location: [%d,%d]\n',uint32(regs.FRMW.zoWorldRow(1)),uint32(regs.FRMW.zoWorldCol(1)));
end

function [results,luts] = fixAng2XYBugWithUndist(runParams, calibParams, results,fw,fnCalib, fprintff, t)
    fprintff('[-] Fixing ang2xy using undist table...\n');
    if(runParams.undist)
        [udistlUT.FRMW.undistModel,udistRegs,results.maxPixelDisplacement,results.undistRms] = Calibration.Undist.calibUndistAng2xyBugFix(fw,calibParams);
        udistRegs.DIGG.undistBypass = false;
        fw.setRegs(udistRegs,fnCalib);
        fw.setLut(udistlUT);
        [~,luts]=fw.get();
        if(results.maxPixelDisplacement<calibParams.errRange.maxPixelDisplacement(2))
            fprintff('[v] undist calib passed[e=%g] [undistRms=%2.2f]\n',results.maxPixelDisplacement,results.undistRms);
        else
            fprintff('[x] undist calib failed[e=%g] [undistRms=%2.2f]\n',results.maxPixelDisplacement,results.undistRms);
            
        end
        ttt=[tempname '.txt'];
        fw.genMWDcmd('DIGGundist_|DIGG|DEST|CBUF',ttt);
%        hw.runScript(ttt);
%        hw.shadowUpdate();
        fprintff('[v] Done(%ds)\n',round(toc(t)));
    else
        [~,luts]=fw.get();
        fprintff('[?] skipped\n');
    end
end

function writeCalibRegsProps(fw,fnCalib)
    regs = fw.get();
    intregs.FRMW.calImgHsize=regs.GNRL.imgHsize;
    intregs.FRMW.calImgVsize=regs.GNRL.imgVsize;

    fw.setRegs(intregs,fnCalib);
    fw.get();
end
