function configurationWriter(algoFldr,outputFldr)
regs2write='DESTp2axa|DESTp2axb|DESTp2aya|DESTp2ayb|DESTtxFRQpd|DIGGang2Xfactor|DIGGang2Yfactor|DIGGangXfactor|DIGGangYfactor|DIGGdx2|DIGGdx3|DIGGdx5|DIGGdy2|DIGGdy3|DIGGdy5|DIGGnx|DIGGny|DIGGundist|EXTLconLoc';
fw=Pipe.loadFirmware(algoFldr);
fw.get();%force autogen


%calibration  output spcript
d=fw.getAddrData(regs2write)';

fid = fopen(fullfile(outputFldr,filesep,'algoCalib.txt'),'w');
fprintf(fid,'mwd %08x %08x // %s\n',d{:});
fclose(fid);

%JFILbypass scripts

fid = fopen(fullfile(outputFldr,filesep,'algoJFILconfig.txt'),'w');
fprintf(fid,fw.genMWDcmd('JFIL.+bypass'));
fclose(fid);

%set conLocRegs
fid = fopen(fullfile(outputFldr,filesep,'algoConLocConfig.txt'),'w');
fprintf(fid,fw.getPresetScript('reset'));
fprintf(fid,'\n');

fprintf(fid,fw.genMWDcmd('EXTLconloc'));
fprintf(fid,'\n');

fprintf(fid,fw.getPresetScript('restart'));
fclose(fid);

end