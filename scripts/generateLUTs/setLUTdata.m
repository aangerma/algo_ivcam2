function regs=setLUTdata(lut)
lutData=lut.data;
lutBlock=lut.block;
lutName=lut.name;



regs.(lutBlock).(lutName) = lutData;
fw = Firmware;
fw.setRegs(regs,[]);
regxChk = fw.get();
assert(all(regxChk.(lutBlock).(lutName)(1:length(lutData))==lutData));
fw.rewriteRegisterFiles();
end