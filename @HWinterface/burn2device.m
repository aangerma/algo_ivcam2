function burn2device(obj,basedir)
    if(~exist('basedir','dir'))
        basedir=tempdir;
    end
    fw=obj.getFirmware();
    fw.writeFirmwareFiles(basedir);
    if(basedir(end)~=filesep)
        basedir(end+1)=filesep;
    end
    filenamesTableIndexLUT=  {
        'WrConfigData','Algo_Dynamic_Configuration_VGA30_1_ConfigData_Ver_01_01.txt','133';
        'WrConfigData','Algo_Dynamic_Configuration_VGA30_2_ConfigData_Ver_01_01.txt','134';
        'WrConfigData','Algo_Dynamic_Configuration_VGA30_3_ConfigData_Ver_01_01.txt','135';
        'WrCalibData' ,'Algo_Pipe_Calibration_VGA_CalibData_Ver_01_01.txt'          ,'0a0';
        'WrConfigInfo','DCOR_cml_0_Info_ConfigInfo_Ver_01_01.bin'                   ,'180';
        'WrConfigInfo','DCOR_cml_1_Info_ConfigInfo_Ver_01_01.bin'                   ,'181';
        'WrConfigInfo','DCOR_cml_2_Info_ConfigInfo_Ver_01_01.bin'                   ,'18B';
        'WrConfigInfo','DCOR_fml_0_Info_ConfigInfo_Ver_01_01.bin'                   ,'182';
        'WrConfigInfo','DCOR_fml_1_Info_ConfigInfo_Ver_01_01.bin'                   ,'183';
        'WrConfigInfo','DCOR_fml_2_Info_ConfigInfo_Ver_01_01.bin'                   ,'184';
        'WrConfigInfo','DCOR_fml_3_Info_ConfigInfo_Ver_01_01.bin'                   ,'185';
        'WrConfigInfo','DCOR_fml_4_Info_ConfigInfo_Ver_01_01.bin'                   ,'186';
        'WrConfigInfo','DCOR_fml_5_Info_ConfigInfo_Ver_01_01.bin'                   ,'187';
        'WrConfigInfo','DCOR_fml_6_Info_ConfigInfo_Ver_01_01.bin'                   ,'188';
        'WrConfigInfo','DCOR_fml_7_Info_ConfigInfo_Ver_01_01.bin'                   ,'189';
        'WrConfigInfo','DCOR_fml_8_Info_ConfigInfo_Ver_01_01.bin'                   ,'18A';
        'WrCalibInfo' ,'DIGG_Gamma_Info_CalibInfo_Ver_01_01.bin'                    ,'030';
        'WrCalibInfo' ,'DIGG_Undist_Info_1_CalibInfo_Ver_01_01.bin'                 ,'040';
        'WrCalibInfo' ,'DIGG_Undist_Info_2_CalibInfo_Ver_01_01.bin'                 ,'041';
        'WrCalibInfo' ,'DIGG_Undist_Info_3_CalibInfo_Ver_01_01.bin'                 ,'042';
        };
    for i=1:size(filenamesTableIndexLUT,1)
        if(~exist(fullfile(basedir,filenamesTableIndexLUT{i,2}),'file'))
            continue;
        end
%         ok=obj.cmd(sprintf('%s "%s%s"',filenamesTableIndexLUT{i,1},basedir,filenamesTableIndexLUT{i,2}));
%         ok=obj.cmd(sprintf('exec_table %s',filenamesTableIndexLUT{i,3}));
        fprintf('%s "%s%s"\n',filenamesTableIndexLUT{i,1},basedir,filenamesTableIndexLUT{i,2});
        fprintf('exec_table %s\n',filenamesTableIndexLUT{i,3})
    end
end
