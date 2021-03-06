function writeFirmwareFiles(obj,outputFldr)
    % Write tables to output folder. For both EPROM and flash.
    % oldFWVersion = true indicates that we should use different
    % version representation for units with firmware lower than 1.1.3.77.
    CALIB_GROUP_KEY='0';
    CALIBR_GROUP_KEY='R';
    CONFIG_GROUP_KEY='1';
    mkdirSafe(outputFldr);
    regs=obj.get();%force autogen
    
    v1=bitand(bitshift(regs.DIGG.spare(1),-16),uint32(255));
    v2=bitand(bitshift(regs.DIGG.spare(1),-8),uint32(255));
    vers = single(v1)+single(v2)/100;
    
    m=obj.getMeta();
    
    %-------------------CALIBRATION-------------------
    calib_regs2write=cell2str({m([m.group]==CALIB_GROUP_KEY).regName},'|');
    calibR_regs2write=cell2str({m([m.group]==CALIBR_GROUP_KEY).regName},'|');
    %
    d=obj.getAddrData(calib_regs2write);
    assert(length(d)<=62,'Max lines in calibration file is limited to 62 due to eprom memmory limitation');
    algoPipeCalibTableFileName = Calibration.aux.genTableBinFileName('Algo_Pipe_Calibration_VGA_CalibData', vers);
    writeMWD(d,fullfile(outputFldr,filesep, [algoPipeCalibTableFileName(1:end-4), '.txt']),1,510);
    
    d=obj.getAddrData(calibR_regs2write);
    reserved512TableFileName = Calibration.aux.genTableBinFileName('Reserved_512_Calibration_2_CalibData', vers);
    writeMWD(d,fullfile(outputFldr,filesep,[reserved512TableFileName(1:end-4) '.txt']),1,62);
    
    undistTableFileName = Calibration.aux.genTableBinFileName('DIGG_Undist_Info_%d_CalibInfo', vers);
    undistfns=obj.writeLUTbin(obj.getAddrData('DIGGundistModel'),fullfile(outputFldr,filesep, undistTableFileName),true);
    
    gammaTableFileName = Calibration.aux.genTableBinFileName('DIGG_Gamma_Info_CalibInfo', vers);
    gammafn =obj.writeLUTbin(obj.getAddrData('DIGGgamma_'),fullfile(outputFldr,filesep, gammaTableFileName));
    
    thermalTableFileName = Calibration.aux.genTableBinFileName('Algo_Thermal_Loop_CalibInfo', vers);
    obj.writeAlgoThermalBin(fullfile(outputFldr,filesep, thermalTableFileName));
    %no room for undist3: concat it to gamma file
    data = [readbin(gammafn{1});readbin(undistfns{3})];
    writebin(gammafn{1},data);
    delete(undistfns{3})
    
    
    %-------------------CONFIGURATION-------------------
    
    config_regs2write=cell2str({m([m.group]==CONFIG_GROUP_KEY).regName},'|');
    
    algoDynamicCfgTableFileName = Calibration.aux.genTableBinFileName('Algo_Dynamic_Configuration_VGA30_%d_ConfigData', vers);
    writeMWD(obj.getAddrData(config_regs2write),fullfile(outputFldr,filesep, [algoDynamicCfgTableFileName(1:end-4), '.txt']),3,510);
    
    dcorCmlTableFileName = Calibration.aux.genTableBinFileName('DCOR_cml_%d_Info_ConfigInfo', vers);
    obj.writeLUTbin(obj.getAddrData('DCORtmpltCrse'),fullfile(outputFldr,filesep, dcorCmlTableFileName));
    
    dcorFmlTableFileName = Calibration.aux.genTableBinFileName('DCOR_fml_%d_Info_ConfigInfo', vers);
    obj.writeLUTbin(obj.getAddrData('DCORtmpltFine'),fullfile(outputFldr,filesep, dcorFmlTableFileName));
    
    
end


function d=readbin(fn)
    fid = fopen(fn,'r');
    d=uint8(fread(fid,'uint8'));
    fclose(fid);
end

function d=writebin(fn,d)
    fid = fopen(fn,'w');
    fwrite(fid,d,'uint8');
    fclose(fid);
end



function writeMWD(d,fn,nMax,PL_SZ)
    
    

    
    n = ceil(size(d,1)/PL_SZ);
    if(n>nMax)
        error('error, too many registers to write!');
    end
    for i=1:nMax
        fid = fopen(sprintf(strrep(fn,'\','\\'),i),'w');
        ibeg = (i-1)*PL_SZ+1;
        iend = min(i*PL_SZ,size(d,1));
        if(i<=n)
            di=d(ibeg:iend,:)';
            fprintf(fid,'mwd %08x %08x // %s\n',di{:});
        else
            fprintf(fid,'mwd a00e0870 00000000 // DO NOTHING\n');%prevent empty file
        end
        fclose(fid);
    end
    
end
