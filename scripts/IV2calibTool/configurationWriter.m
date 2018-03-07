function configurationWriter(algoFldr,outputFldr)
fw=Pipe.loadFirmware(algoFldr);
regs=fw.get();%force autogen

v1=bitand(bitshift(regs.DIGG.spare(1),8),uint32(15));
v2=bitand(bitshift(regs.DIGG.spare(1),4),uint32(15));
v3=bitand(bitshift(regs.DIGG.spare(1),0),uint32(15));
filepostfix = sprintf('_ver_%03d.%03d.%03d.',v1,v2,v3);


%calibration  output spcript
regs2write='DESTp2axa|DESTp2axb|DESTp2aya|DESTp2ayb|DESTtxFRQpd|DIGGang2Xfactor|DIGGang2Yfactor|DIGGangXfactor|DIGGangYfactor|DIGGdx2|DIGGdx3|DIGGdx5|DIGGdy2|DIGGdy3|DIGGdy5|DIGGnx|DIGGny|DIGGundist[^?=Model]+|EXTLconLoc';
d=fw.getAddrData(regs2write)';

fid = fopen(fullfile(outputFldr,filesep,['Algo_Pipe_Calibration_VGA_CalibData_' filepostfix 'txt']),'w');
fprintf(fid,'mwd %08x %08x // %s\n',d{:});
fclose(fid);

fid = fopen(fullfile(outputFldr,filesep,['DIGG_Gamma_Info_CalibInfo_' filepostfix 'bin']),'w');
fwrite(fid,getLUTdata(fw.getAddrData('DIGGgamma_')),'uint8');
fclose(fid);

d=fw.getAddrData('DIGGundistModel');
fidA = fopen(fullfile(outputFldr,filesep,['DIGG_Undist_Info_1_CalibInfo' filepostfix 'bin']),'w');
fidB = fopen(fullfile(outputFldr,filesep,['DIGG_Undist_Info_2_CalibInfo' filepostfix 'bin']),'w');

fwrite(fidA,getLUTdata(d(1:1024,:)),'uint8');
fwrite(fidB,getLUTdata(d(1025:end,:)),'uint8');
fclose(fidA);
fclose(fidB);


%all
fid = fopen(fullfile(algoFldr,filesep,'algoCalibMWD.txt'),'w');
fprintf(fid,fw.genMWDcmd('.'));
fclose(fid);


%JFILbypass scripts
fid = fopen(fullfile(algoFldr,filesep,'algoJFILconfigMWD.txt'),'w');
fprintf(fid,fw.genMWDcmd('JFIL.+bypass'));
fclose(fid);

%set conLocRegs
fid = fopen(fullfile(algoFldr,filesep,'algoConLocConfigMWD.txt'),'w');
fprintf(fid,fw.getPresetScript('reset'));
fprintf(fid,'\n');

fprintf(fid,fw.genMWDcmd('EXTLconloc'));
fprintf(fid,'\n');

fprintf(fid,fw.getPresetScript('restart'));
fclose(fid);

end
function s=getLUTdata(addrdata)
data = [addrdata{:,2}];
data = buffer(data,ceil(length(data)/4)*4)';
addr = uint32(addrdata{1,1});

touint8 = @(x,n)  vec(flipud(reshape(typecast(x,'uint8'),n,[])))';

s=[uint8(133) uint8(7) touint8(uint32(addr),4) touint8(uint16(length(data)),2) touint8(data,4)];
end
