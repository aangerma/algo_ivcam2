function configurationWriter(algoFldr,outputFldr)
mkdirSafe(outputFldr);
fw=Pipe.loadFirmware(algoFldr);
regs=fw.get();%force autogen

v1=bitand(bitshift(regs.DIGG.spare(1),-8),uint32(15));
v2=bitand(bitshift(regs.DIGG.spare(1),0),uint32(15));
filepostfix = sprintf('_ver_%02d_%02d.',v1,v2);


%calibration  output spcript
regs2write='DESTp2axa|DESTp2axb|DESTp2aya|DESTp2ayb|DESTtxFRQpd|DIGGang2Xfactor|DIGGang2Yfactor|DIGGangXfactor|DIGGangYfactor|DIGGdx2|DIGGdx3|DIGGdx5|DIGGdy2|DIGGdy3|DIGGdy5|DIGGnx|DIGGny|DIGGundist[^?=Model]+|EXTLconLoc';
d=fw.getAddrData(regs2write);
fid = fopen(fullfile(outputFldr,filesep,['Algo_Pipe_Calibration_VGA_CalibData' filepostfix 'txt']),'w');
fprintf(fid,'mwd %08x %08x // %s\n',d{:});
fclose(fid);

%configuration

configregs2write=['^(?!' regs2write '|JFILdnn|JFILinn|STAT|FRMW|DCORtmpltCrse|DCORtmpltFine|DIGGundistModel).'];
d=fw.getAddrData(configregs2write);
writeMWD(d,fullfile(outputFldr,filesep,['Algo_Dynamic_Configuration_VGA30_%d_ConfigData' filepostfix 'txt']));
% fid = fopen(fullfile(outputFldr,filesep,['Algo_Dynamic_Configuration_VGA30_1_ConfigData' filepostfix 'txt']),'w');
% fprintf(fid,'mwd %08x %08x // %s\n',d{:});
% fclose(fid);


fid = fopen(fullfile(outputFldr,filesep,['DIGG_Gamma_Info_CalibInfo' filepostfix 'bin']),'w');
fwrite(fid,getLUTdata(fw.getAddrData('DIGGgamma_')),'uint8');
fclose(fid);

% d=fw.getAddrData('DIGGundistModel');
% writeLUTbin(d,fullfile(outputFldr,filesep,['DIGG_Undist_%d_Info_CalibInfo' filepostfix 'bin']));

d=fw.getAddrData('DCORtmpltCrse');
writeLUTbin(d,fullfile(outputFldr,filesep,['DCOR_cml_%d_Info_ConfigInfo' filepostfix 'bin']));

d=fw.getAddrData('DCORtmpltFine');
writeLUTbin(d,fullfile(outputFldr,filesep,['DCOR_fml_%d_Info_ConfigInfo' filepostfix 'bin']));


%-------------------------INTERNALS-----------------------------------------
fid = fopen(fullfile(algoFldr,filesep,'algoCalibMWD.txt'),'w');
fprintf(fid,fw.genMWDcmd('.'));
fclose(fid);


%JFILbypass scripts
fid = fopen(fullfile(algoFldr,filesep,'algoJFILconfigMWD.txt'),'w');
fprintf(fid,fw.genMWDcmd('JFIL.+bypass'));
fclose(fid);

%set conLocRegs
fid = fopen(fullfile(algoFldr,filesep,'algoConLocConfigMWD.txt'),'w');
fprintf(fid,fileread(fw.getPresetScript('reset')));
fprintf(fid,'\n');

fprintf(fid,fw.genMWDcmd('EXTLconloc'));
fprintf(fid,'\n');

fprintf(fid,fileread(fw.getPresetScript('restart')));
fclose(fid);

end
function s=getLUTdata(addrdata)

%ALL SHOULD BE LITTLE ENDIAN
data = [addrdata{:,2}];
data = buffer(data,ceil(length(data)/4)*4)';
addr = uint32(addrdata{1,1});

touint8 = @(x,n)  vec((reshape(typecast(x,'uint8'),n,[])))';

s=[uint8(133) uint8(7) touint8(uint32(addr),4) touint8(uint16(length(data)),2) touint8(data,4)];
end

function ilast=writeLUTbin(d,fn)
PL_SZ=4072*8/32;

n = ceil(size(d,1)/PL_SZ);
for i=0:n-1
    fid = fopen(sprintf(strrep(fn,'\','\\'),i),'w');
    ibeg = i*PL_SZ+1;
    iend = min((i+1)*PL_SZ,size(d,1));
    fwrite(fid,getLUTdata(d(ibeg:iend,:)),'uint8');
    fclose(fid);
end
ilast = iend;


end

function writeMWD(d,fn)

PL_SZ=510;

n = ceil(size(d,1)/PL_SZ);
for i=0:n-1
    fid = fopen(sprintf(strrep(fn,'\','\\'),i),'w');
    ibeg = i*PL_SZ+1;
    iend = min((i+1)*PL_SZ,size(d,1));
    di=d(ibeg:iend,:)';
    fprintf(fid,'mwd %08x %08x // %s\n',di{:});
    fclose(fid);
end

end
