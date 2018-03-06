function configurationWriter(algoFldr,outputFldr)
regs2write='DESTp2axa|DESTp2axb|DESTp2aya|DESTp2ayb|DESTtxFRQpd|DIGGang2Xfactor|DIGGang2Yfactor|DIGGangXfactor|DIGGangYfactor|DIGGdx2|DIGGdx3|DIGGdx5|DIGGdy2|DIGGdy3|DIGGdy5|DIGGnx|DIGGny|DIGGundist|EXTLconLoc';
fw=Pipe.loadFirmware(algoFldr);
fw.get();%force autogen
d=fw.getAddrData(regs2write);
d=d';
fid = fopen(fullfile(outputFldr,filesep,'algoCalib.txt'),'w');
fprintf(fid,'mwd %08x %08x // %s\n',d{:});
fclose(fid);
end