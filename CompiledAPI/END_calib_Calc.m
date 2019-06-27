%function [results ,luts] = END_calib_Calc(verValue,verValueFull,delayRegs, dsmregs,roiRegs,dfzRegs,results,fnCalib,calibParams,undist_flag)
function [results ,luts] = END_calib_Calc(delayRegs, dsmregs,roiRegs,dfzRegs,results,fnCalib,calibParams,undist_flag)
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
        fn = fullfile(g_output_dir, 'mat_files' , [func_name '_in.mat']);
        save(fn,'delayRegs', 'dsmregs' ,'roiRegs','dfzRegs','results','fnCalib' ,'calibParams');
    end
    runParams.outputFolder = g_output_dir;
    runParams.undist = undist_flag;
    [~,~,versionBytes] = calibToolVersion();
    verValue           = uint32(versionBytes(1))*2^8 + uint32(versionBytes(2));%0x00000203
    verValueFull       = uint32(versionBytes(1))*2^16 +uint32(versionBytes(2))*2^8+uint32(versionBytes(3));%0x00020300 

    
    [results ,luts] = final_calib(runParams,verValue,verValueFull,delayRegs, dsmregs,roiRegs,dfzRegs,results,fnCalib, fprintff, calibParams,g_output_dir);    % save output
    if g_save_output_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files', [func_name '_out.mat']);
        save(fn,'results', 'luts');
    end

end

function [results ,undistLuts] = final_calib(runParams,verValue,verValueFull,delayRegs, dsmregs,roiRegs,dfzRegs,results,fnCalib, fprintff, calibParams,output_dir)
    t = tic;
    %% load inital FW.
%    fw = Pipe.loadFirmware(internalFolder);
    path = fileparts(fnCalib);
    if(exist(fullfile(path , 'regsDefinitions.frmw'), 'file') == 2)
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
    [results,undistRegs,undistLuts] = fixAng2XYBugWithUndist(runParams, calibParams, results,fw,fnCalib, fprintff, t);
    fw.setRegs(undistRegs,fnCalib);
    fw.setLut(undistLuts);
    fw.get();
    temp_dir = fullfile(output_dir,'AlgoInternal');
    mkdirSafe(temp_dir);
    fn = fullfile(temp_dir,'postUndistState.txt');
    fw.genMWDcmd('DIGGundist_|DIGG|DEST|CBUF',fn);
    %% prepare preset table
    calibTempTableFn = fullfile(output_dir,sprintf('Dynamic_Range_Info_CalibInfo_Ver_%02d_%02d.bin',0,bitand(verValue,hex2dec('ff'))));    
    presetPath = path; 
    fw.writeDynamicRangeTable(calibTempTableFn,presetPath);
    %% Print image final fov
    [results,~] = Calibration.aux.calcImFov(fw,results,calibParams,fprintff);
    fnUndsitLut = fullfile(output_dir,'FRMWundistModel.bin32');
    writeCalibRegsProps(fw,fnCalib);
    fw.writeUpdated(fnCalib);
    io.writeBin(fnUndsitLut,undistLuts.FRMW.undistModel);
    fw.writeFirmwareFiles(output_dir);
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
    intregs.DIGG.spare(7)=uint32(typecast(regs.FRMW.calMarginL,'uint16'))*2^16 + uint32(typecast(regs.FRMW.calMarginR,'uint16'));
    intregs.DIGG.spare(8)=uint32(typecast(regs.FRMW.calMarginT,'uint16'))*2^16 + uint32(typecast(regs.FRMW.calMarginB,'uint16'));
    intregs.JFIL.spare=zeros(1,8,'uint32');
    %[zoCol,zoRow] = Calibration.aux.zoLoc(fw);
    intregs.JFIL.spare(1)=uint32(regs.FRMW.zoWorldRow(1))*2^16 + uint32(regs.FRMW.zoWorldCol(1));
    intregs.JFIL.spare(2)=typecast(regs.FRMW.dfzCalTmp,'uint32');
    intregs.JFIL.spare(3)=typecast(single(regs.FRMW.pitchFixFactor),'uint32');
    intregs.JFIL.spare(4)=typecast(single(regs.FRMW.polyVars(1)),'uint32');
    intregs.JFIL.spare(5)=typecast(single(regs.FRMW.polyVars(2)),'uint32');
    intregs.JFIL.spare(6)=typecast(single(regs.FRMW.polyVars(3)),'uint32');
    intregs.JFIL.spare(7)=typecast(regs.FRMW.dfzApdCalTmp,'uint32');
    
    
    dcorSpares = zeros(1,8,'single');
    dcorSpares(3:5) = single(regs.FRMW.dfzVbias);
    dcorSpares(6:8) = single(regs.FRMW.dfzIbias);
    intregs.DCOR.spare = dcorSpares;
    
    % undistAngVert & undistAngHorz
%     pckrSpares = zeros(1,8,'single');
%     pckrSpares(7:8) = single(regs.FRMW.undistAngVert(1:2));
%     intregs.PCKR.spare = pckrSpares;
%     
%     statSpares = single([regs.FRMW.undistAngVert(3:5),regs.FRMW.undistAngHorz]);
%     intregs.STAT.spare = statSpares;
    
    JFILdnnWeights = regs.JFIL.dnnWeights;
    JFILdnnWeights(1:10) = typecast([regs.FRMW.undistAngVert,regs.FRMW.undistAngHorz],'uint32');
    intregs.JFIL.dnnWeights = JFILdnnWeights;
    
    fw.setRegs(intregs,fnCalib);
    fw.get();
    
    fprintff('Zero Order Pixel Location: [%d,%d]\n',uint32(regs.FRMW.zoWorldRow(1)),uint32(regs.FRMW.zoWorldCol(1)));
end

function [results,udistRegs,udistlUT] = fixAng2XYBugWithUndist(runParams, calibParams, results,fw,fnCalib, fprintff, t)
    fprintff('[-] Fixing ang2xy using undist table...\n');
    if(runParams.undist)
        [udistlUT.FRMW.undistModel,udistRegs,results.maxPixelDisplacement] = Calibration.Undist.calibUndistAng2xyBugFix(fw,runParams);
        udistRegs.DIGG.undistBypass = false;
        if(results.maxPixelDisplacement<calibParams.errRange.maxPixelDisplacement(2))
            fprintff('[v] undist calib passed[e=%g]\n',results.maxPixelDisplacement);
        else
            fprintff('[x] undist calib failed[e=%g]\n',results.maxPixelDisplacement);
            
        end
%         ttt=[tempname '.txt'];
        
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
