function configurationWriter(algoFldr,outputFldr)
regs2write='DESTp2axa|DESTp2axb|DESTp2aya|DESTp2ayb|DESTtxFRQpd|DIGGang2Xfactor|DIGGang2Yfactor|DIGGangXfactor|DIGGangYfactor|DIGGdx2|DIGGdx3|DIGGdx5|DIGGdy2|DIGGdy3|DIGGdy5|DIGGnx|DIGGny|DIGGundist|EXTLconLoc';
fw=Pipe.loadFirmware(algoFldr);
fw.get();%force autogen
d=fw.getMeta(regs2write);
txt = strrep(cell2str(strcat('mwd_',dec2hex([d.address]),'_',dec2hex([d.valueUINT32]),'__//',{d.algoBlock}',{d.algoName}'),newline),'_',' ');
fid = fopen(fullfile(outputFldr,filesep,'algoCalib.txt'),'w');
fprintf(fid,txt);
fclose(fid);
end