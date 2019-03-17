function writeFirmwareFiles(obj,outputFldr,oldFWVersion)
    % Write tables to output folder. For both EPROM and flash.
    % oldFWVersion = true indicates that we should use different
    % version representation for units with firmware lower than 1.1.3.77.
    CALIB_GROUP_KEY='0';
    CALIBR_GROUP_KEY='R';
    CONFIG_GROUP_KEY='1';
    mkdirSafe(outputFldr);
    regs=obj.get();%force autogen
    
    v1=bitand(bitshift(regs.DIGG.spare(1),-8),uint32(255));
    v2=bitand(bitshift(regs.DIGG.spare(1),0),uint32(255));
    configpostfix = sprintf('_Ver_%02d_%02d.',v1,v2);
    if oldFWVersion
        calibpostfix = sprintf('_Ver_%02d_%02d.',v2,v1);
    else
        calibpostfix = sprintf('_Ver_%02d_%02d.',v1,v2);
    end
    
    
    m=obj.getMeta();
    
    %-------------------CALIBRATION-------------------
    calib_regs2write=cell2str({m([m.group]==CALIB_GROUP_KEY).regName},'|');
    calibR_regs2write=cell2str({m([m.group]==CALIBR_GROUP_KEY).regName},'|');
    %
    d=obj.getAddrData(calib_regs2write);
    assert(length(d)<=62,'Max lines in calibration file is limited to 62 due to eprom memmory limitation');
    writeMWD(d,fullfile(outputFldr,filesep,['Algo_Pipe_Calibration_VGA_CalibData' calibpostfix 'txt']),1,510);
    
    d=obj.getAddrData(calibR_regs2write);
    writeMWD(d,fullfile(outputFldr,filesep,['Reserved_512_Calibration_%d_CalibData' calibpostfix 'txt']),2,62);
    
    
    undistfns=obj.writeLUTbin(obj.getAddrData('DIGGundistModel'),fullfile(outputFldr,filesep,['DIGG_Undist_Info_%d_CalibInfo' calibpostfix 'bin']),true);
    
    gammafn =obj.writeLUTbin(obj.getAddrData('DIGGgamma_'),fullfile(outputFldr,filesep,['DIGG_Gamma_Info_CalibInfo' calibpostfix 'bin']));
    
    obj.writeAlgoThermalBin(fullfile(outputFldr,filesep,['Algo_Thermal_Loop_CalibInfo' calibpostfix 'bin']))
    %no room for undist3: concat it to gamma file
    data = [readbin(gammafn{1});readbin(undistfns{3})];
    writebin(gammafn{1},data);
    delete(undistfns{3})
    
    
    %-------------------CONFIGURATION-------------------
    
    config_regs2write=cell2str({m([m.group]==CONFIG_GROUP_KEY).regName},'|');
    
    writeMWD(obj.getAddrData(config_regs2write),fullfile(outputFldr,filesep,['Algo_Dynamic_Configuration_VGA30_%d_ConfigData' configpostfix 'txt']),3,510);
    
    obj.writeLUTbin(obj.getAddrData('DCORtmpltCrse'),fullfile(outputFldr,filesep,['DCOR_cml_%d_Info_ConfigInfo' configpostfix 'bin']));
    
    obj.writeLUTbin(obj.getAddrData('DCORtmpltFine'),fullfile(outputFldr,filesep,['DCOR_fml_%d_Info_ConfigInfo' configpostfix 'bin']));
    
    
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
