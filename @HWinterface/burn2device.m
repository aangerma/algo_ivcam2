function burn2device(obj,basedir,burnCalib,burnConfig)
    if(~exist(basedir,'dir'))
        basedir=tempdir;
    end
    if(~exist('burnConfig','var'))
        burnConfig=false;
    end
    
    if(~exist('burnCalib','var'))
        burnCalib=false;
    end
    
%     fw=obj.getFirmware();
%     oldFWVersion = checkFWVersion(obj);
%     fw.writeFirmwareFiles(basedir,oldFWVersion);
    if(basedir(end)~=filesep)
        basedir(end+1)=filesep;
    end
    filenamesTableIndexLUT={};
    if(burnCalib)
        filenamesTableIndexLUT(end+1,:)={ 'WrCalibData' ,'Algo_Pipe_Calibration_VGA_CalibData_Ver_*.txt'          ,'0a0'};
        filenamesTableIndexLUT(end+1,:)={ 'WrCalibData' ,'Reserved_512_Calibration_1_CalibData_Ver_*.txt'         ,'0a1'};
        filenamesTableIndexLUT(end+1,:)={ 'WrCalibData' ,'Reserved_512_Calibration_2_CalibData_Ver_*.txt'         ,'0a2'};
        filenamesTableIndexLUT(end+1,:)={ 'WrCalibInfo' ,'DIGG_Gamma_Info_CalibInfo_Ver_*.bin'                    ,'030'};
        filenamesTableIndexLUT(end+1,:)={ 'WrCalibInfo' ,'Algo_Thermal_Loop_CalibInfo_Ver_*.bin'                  ,'00d'};
        filenamesTableIndexLUT(end+1,:)={ 'WrCalibInfo' ,'DIGG_Undist_Info_1_CalibInfo_Ver_*.bin'                 ,'040'};
        filenamesTableIndexLUT(end+1,:)={ 'WrCalibInfo' ,'DIGG_Undist_Info_2_CalibInfo_Ver_*.bin'                 ,'041'};
        filenamesTableIndexLUT(end+1,:)={ 'WrCalibInfo' ,'RGB_int_ext_Info_CalibInfo_Ver_*.bin'                   ,'010'};
    end
    if(burnConfig)
            filenamesTableIndexLUT(end+1,:)={'WrConfigData','Algo_Dynamic_Configuration_VGA30_1_ConfigData_Ver_*.txt','133'};
            filenamesTableIndexLUT(end+1,:)={'WrConfigData','Algo_Dynamic_Configuration_VGA30_2_ConfigData_Ver_*.txt','134'};
            filenamesTableIndexLUT(end+1,:)={'WrConfigData','Algo_Dynamic_Configuration_VGA30_3_ConfigData_Ver_*.txt','135'};
            filenamesTableIndexLUT(end+1,:)={'WrConfigInfo','DCOR_cml_0_Info_ConfigInfo_Ver_*.bin'                   ,'180'};
            filenamesTableIndexLUT(end+1,:)={'WrConfigInfo','DCOR_cml_1_Info_ConfigInfo_Ver_*.bin'                   ,'181'};
            filenamesTableIndexLUT(end+1,:)={'WrConfigInfo','DCOR_cml_2_Info_ConfigInfo_Ver_*.bin'                   ,'18B'};
            filenamesTableIndexLUT(end+1,:)={'WrConfigInfo','DCOR_fml_0_Info_ConfigInfo_Ver_*.bin'                   ,'182'};
            filenamesTableIndexLUT(end+1,:)={'WrConfigInfo','DCOR_fml_1_Info_ConfigInfo_Ver_*.bin'                   ,'183'};
            filenamesTableIndexLUT(end+1,:)={'WrConfigInfo','DCOR_fml_2_Info_ConfigInfo_Ver_*.bin'                   ,'184'};
            filenamesTableIndexLUT(end+1,:)={'WrConfigInfo','DCOR_fml_3_Info_ConfigInfo_Ver_*.bin'                   ,'185'};
            filenamesTableIndexLUT(end+1,:)={'WrConfigInfo','DCOR_fml_4_Info_ConfigInfo_Ver_*.bin'                   ,'186'};
            filenamesTableIndexLUT(end+1,:)={'WrConfigInfo','DCOR_fml_5_Info_ConfigInfo_Ver_*.bin'                   ,'187'};
            filenamesTableIndexLUT(end+1,:)={'WrConfigInfo','DCOR_fml_6_Info_ConfigInfo_Ver_*.bin'                   ,'188'};
            filenamesTableIndexLUT(end+1,:)={'WrConfigInfo','DCOR_fml_7_Info_ConfigInfo_Ver_*.bin'                   ,'189'};
            filenamesTableIndexLUT(end+1,:)={'WrConfigInfo','DCOR_fml_8_Info_ConfigInfo_Ver_*.bin'                   ,'18A'};

    end
    for i=1:size(filenamesTableIndexLUT,1)
        fn = dir(fullfile(basedir,filenamesTableIndexLUT{i,2}));
        
        if(length(fn)~=1)
            warning('could not burn table %s',filenamesTableIndexLUT{i,2})
            continue;
        end
            fn=fullfile(basedir,fn(1).name);
        
            cmdA = sprintf('%s "%s"',filenamesTableIndexLUT{i,1},fn);
        
            
        
%         cmdB = sprintf('exec_table %s',filenamesTableIndexLUT{i,3});
        try
            ret=obj.cmd(cmdA);
        catch
            warning('cmd %s failed',cmdA);
        end
%         ret=obj.cmd(cmdB);
        
        
    end
     
end

function oldVersion = checkFWVersion(obj)
    % Checks if fw version is smaller (or equal) to 1.1.3.77
    gvdstr = obj.cmd('gvd');
    linenum = strfind(gvdstr,'FunctionalPayloadVersion:');
    gvdTargetLine = gvdstr(linenum:end);
    lineDownI = strsplit(gvdTargetLine);
    fwStr = strsplit(lineDownI{2},'.');
    
    if any(isnan(str2double(fwStr)))
       error('fw version %s contains non numeric values.',lineDownI{2}); 
    else
        fwNumbers = str2double(fwStr);
        fwVer = [1e+5,1e+4,1e+3,1e+0]*fwNumbers';
    end
    oldVersion = fwVer<=113077;
end
