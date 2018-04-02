function regs=setAbsDelay(hw, inputDelay, fast)


hw.runPresetScript('maReset');

if (fast)
    
    absFast = inputDelay;
    absSlow = readF(hw)+readS(hw);
    if(absFast>absSlow)
    %warning('slow delay cannot get smaller value than fast delay,raising slow delay');
    absSlow=absFast;
    end
    
else
    absSlow = inputDelay;
    absFast = readF(hw);
    if(absFast>absSlow)
    %warning('slow delay cannot get smaller value than fast delay,lowering fast delay');
    absFast=absSlow;
    end
end
regs=writeAbsVals(hw,absFast,absSlow);
hw.runPresetScript('maRestart');
end

function v=readF(hw)
    v=hw.read('EXTLconLocDelayFastF')+hw.read('EXTLconLocDelayFastC');
end

function v=readS(hw)
    v=bitand(hw.read('EXTLconLocDelaySlow'),hex2dec('7fff'));
end

function regs=writeAbsVals(hw,absFast,absSlow)
    %{
//---------FAST-------------
mwd a0050548 a005054c 00007110 //[m_regmodel.proj_proj.RegsProjConLocDelay]                      (moves loc+metadata to Hfsync 8inc)
mwd a0050458 a005045c 00000004 //[m_regmodel.proj_proj.RegsProjConLocDelayHfclkRes] TYPE_REG     (moves loc+metadata to Hfsync [0-7])
//--------SLOW-------------
mwd a0060008 a006000c 80000020  //[m_regmodel.ansync_ansync_rt.RegsAnsyncAsLateLatencyFixEn] TYPE_REG
%}


relSlow = absSlow-absFast;

regs.EXTL.conLocDelaySlow = uint32(relSlow)+uint32(bitshift(1,31));
mod8=mod(absFast,8);
regs.EXTL.conLocDelayFastC= uint32(absFast-mod8);
regs.EXTL.conLocDelayFastF=uint32(mod8);
hw.setReg('EXTLconLocDelaySlow',regs.EXTL.conLocDelaySlow);
hw.setReg('EXTLconLocDelayFastC',regs.EXTL.conLocDelayFastC);
hw.setReg('EXTLconLocDelayFastF',regs.EXTL.conLocDelayFastF);
end

