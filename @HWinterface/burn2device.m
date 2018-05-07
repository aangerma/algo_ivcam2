function burn2device(obj,basedir,burunConfiguration)
    if(~exist('basedir','dir'))
        basedir=tempdir;
    end
    if(~exist('burunConfiguration','var'))
        burunConfiguration=false;
    end
    fw=obj.getFirmware();
    fw.writeFirmwareFiles(basedir);
    if(basedir(end)~=filesep)
        basedir(end+1)=filesep;
    end
    filenamesTableIndexLUT=  {
        'WrCalibData' ,'Algo_Pipe_Calibration_VGA_CalibData_Ver_*.txt'          ,'0a0';
        'WrCalibInfo' ,'DIGG_Gamma_Info_CalibInfo_Ver_*.bin'                    ,'030';
        'WrCalibInfo' ,'DIGG_Undist_Info_1_CalibInfo_Ver_*.bin'                 ,'040';
        'WrCalibInfo' ,'DIGG_Undist_Info_2_CalibInfo_Ver_*.bin'                 ,'041';
        };
    if(burunConfiguration)
        filenamesTableIndexLUT(end+1:end+15,:)=  {
            'WrConfigData','Algo_Dynamic_Configuration_VGA30_1_ConfigData_Ver_*.txt','133';
            'WrConfigData','Algo_Dynamic_Configuration_VGA30_2_ConfigData_Ver_*.txt','134';
            'WrConfigData','Algo_Dynamic_Configuration_VGA30_3_ConfigData_Ver_*.txt','135';
            'WrConfigInfo','DCOR_cml_0_Info_ConfigInfo_Ver_*.bin'                   ,'180';
            'WrConfigInfo','DCOR_cml_1_Info_ConfigInfo_Ver_*.bin'                   ,'181';
            'WrConfigInfo','DCOR_cml_2_Info_ConfigInfo_Ver_*.bin'                   ,'18B';
            'WrConfigInfo','DCOR_fml_0_Info_ConfigInfo_Ver_*.bin'                   ,'182';
            'WrConfigInfo','DCOR_fml_1_Info_ConfigInfo_Ver_*.bin'                   ,'183';
            'WrConfigInfo','DCOR_fml_2_Info_ConfigInfo_Ver_*.bin'                   ,'184';
            'WrConfigInfo','DCOR_fml_3_Info_ConfigInfo_Ver_*.bin'                   ,'185';
            'WrConfigInfo','DCOR_fml_4_Info_ConfigInfo_Ver_*.bin'                   ,'186';
            'WrConfigInfo','DCOR_fml_5_Info_ConfigInfo_Ver_*.bin'                   ,'187';
            'WrConfigInfo','DCOR_fml_6_Info_ConfigInfo_Ver_*.bin'                   ,'188';
            'WrConfigInfo','DCOR_fml_7_Info_ConfigInfo_Ver_*.bin'                   ,'189';
            'WrConfigInfo','DCOR_fml_8_Info_ConfigInfo_Ver_*.bin'                   ,'18A';
            };
    end
    for i=1:size(filenamesTableIndexLUT,1)
        fn = dir(fullfile(basedir,filenamesTableIndexLUT{i,2}));
       
        if(length(fn)~=1)
            warning('could not burn table %s',filenamesTableIndexLUT{i,2})
            continue;
        end
         fn=fullfile(basedir,fn(1).name);
       
        cmdA = sprintf('%s "%s"',filenamesTableIndexLUT{i,1},fn);
        cmdB = sprintf('exec_table %s',filenamesTableIndexLUT{i,3});
        obj.cmd(cmdA);
        obj.cmd(cmdB);
        
        
    end
end
