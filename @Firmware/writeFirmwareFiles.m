function writeFirmwareFiles(obj,outputFldr)
    
    CALIB_GROUP_KEY='0';
    CALIBR_GROUP_KEY='R';
    CONFIG_GROUP_KEY='1';
    mkdirSafe(outputFldr);
    regs=obj.get();%force autogen
    
    v1=bitand(bitshift(regs.DIGG.spare(1),-8),uint32(15));
    v2=bitand(bitshift(regs.DIGG.spare(1),0),uint32(15));
    filepostfix = sprintf('_Ver_%02d_%02d.',v1,v2);
    
    m=obj.getMeta();
    
    %-------------------CALIBRATION-------------------
    calib_regs2write=cell2str({m([m.group]==CALIB_GROUP_KEY).regName},'|');
    calibR_regs2write=cell2str({m([m.group]==CALIBR_GROUP_KEY).regName},'|');
    %
    d=obj.getAddrData(calib_regs2write);
    assert(length(d)<=62,'Max lines in calibration file is limited to 62 due to eprom memmory limitation');
    writeMWD(d,fullfile(outputFldr,filesep,['Algo_Pipe_Calibration_VGA_CalibData' filepostfix 'txt']),1,510);
    
    d=obj.getAddrData(calibR_regs2write);
    writeMWD(d,fullfile(outputFldr,filesep,['Reserved_512_Calibration_%d_CalibData_Ver_' filepostfix 'txt']),2,62);
    
    
    undistfns=writeLUTbin(obj.getAddrData('DIGGundistModel'),fullfile(outputFldr,filesep,['DIGG_Undist_Info_%d_CalibInfo' filepostfix 'bin']),true);
    
    gammafn =writeLUTbin(obj.getAddrData('DIGGgamma_'),fullfile(outputFldr,filesep,['DIGG_Gamma_Info_CalibInfo' filepostfix 'bin']));
    
    %no room for undist3: concat it to gamma file
    data = [readbin(gammafn{1});readbin(undistfns{3})];
    writebin(gammafn{1},data);
    delete(undistfns{3})
    
    
    %-------------------CONFIGURATION-------------------
    
    config_regs2write=cell2str({m([m.group]==CONFIG_GROUP_KEY).regName},'|');
    
    writeMWD(obj.getAddrData(config_regs2write),fullfile(outputFldr,filesep,['Algo_Dynamic_Configuration_VGA30_%d_ConfigData' filepostfix 'txt']),3,510);
    
    writeLUTbin(obj.getAddrData('DCORtmpltCrse'),fullfile(outputFldr,filesep,['DCOR_cml_%d_Info_ConfigInfo' filepostfix 'bin']));
    
    writeLUTbin(obj.getAddrData('DCORtmpltFine'),fullfile(outputFldr,filesep,['DCOR_fml_%d_Info_ConfigInfo' filepostfix 'bin']));
    
    
end
function s=getLUTdata(addrdata)
    
    %ALL SHOULD BE LITTLE ENDIAN
    data = [addrdata{:,2}];
    addr = uint32(addrdata{1,1});
    
    touint8 = @(x,n)  vec((reshape(typecast(x,'uint8'),n,[])))';
    
    s=[uint8(133) uint8(7) touint8(uint32(addr),4) touint8(uint16(length(data)),2) touint8(data,4)];
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

function fns=writeLUTbin(d,fn,oneBaseCount)
    if ~exist('oneBaseCount','var')
        oneBaseCount = false;
    end
    PL_SZ=4072*8/32;
    
    n = ceil(size(d,1)/PL_SZ);
    fns=cell(n,1);
    for i=0:n-1
        fns{i+1}=sprintf(strrep(fn,'\','\\'),i+oneBaseCount*1);
        fid = fopen(fns{i+1},'w');
        ibeg = i*PL_SZ+1;
        iend = min((i+1)*PL_SZ,size(d,1));
        fwrite(fid,getLUTdata(d(ibeg:iend,:)),'uint8');
        fclose(fid);
    end
    
    
    
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
        end
        fclose(fid);
    end
    
end
