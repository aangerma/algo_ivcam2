function hwSetDelay(hw, delay, fast)

%{
//---------FAST-------------
mwd a0050548 a005054c 00007110 //[m_regmodel.proj_proj.RegsProjConLocDelay]                      (moves loc+metadata to Hfsync 8inc)
mwd a0050458 a005045c 00000004 //[m_regmodel.proj_proj.RegsProjConLocDelayHfclkRes] TYPE_REG     (moves loc+metadata to Hfsync [0-7])
//--------SLOW-------------
mwd a0060008 a006000c 80000020  //[m_regmodel.ansync_ansync_rt.RegsAnsyncAsLateLatencyFixEn] TYPE_REG
%}

if (fast)
    mod8 = mod(delay, 8);
    hw.setReg('EXTLconLocDelayFastC', uint32(delay - mod8));
    hw.setReg('EXTLconLocDelayFastF', uint32(mod8));
else
    hw.setReg('EXTLconLocDelaySlow', uint32(delay)+uint32(bitshift(1,31)));
end

%hw.shadowUpdate();

hw.runPresetScript('maReset');
hw.runPresetScript('maRestart');

pause(0.2);

end


