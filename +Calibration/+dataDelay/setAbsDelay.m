function [regs, absFast, absSlow]=setAbsDelay(hw, absFast, absSlow)


hw.runPresetScript('maReset');
%{

 |--------absfast-------|

 |                      |
 |-------conloc---------|
 |                      |
fast                 location
   |                    |
   |--------------------|
   |                    |
  slow
   |-------absslow------|

 |--|
latelatency



%}

%no input(just get register value)
if(isempty(absSlow) && isempty(absFast))
    absSlow = read_conloc(hw)-read_latelate(hw);
    absFast = read_conloc(hw);
%both input
elseif(~isempty(absSlow) && ~isempty(absFast))
    if(absFast<absSlow)
        %     warning('slow delay cannot get greater value than fast delay,lowering slow delay');
        mv=round((absFast+absSlow)/2);
        absSlow=mv;
        absFast=mv;
    end
%only fast input
elseif(isempty(absSlow))
    absSlow = read_conloc(hw)-read_latelate(hw);
     if(absFast<absSlow)
        %     warning('slow delay cannot get greater value than fast delay,lowering slow delay');
        absSlow=absFast;
    end
%only slow input
elseif(isempty(absFast))
    absFast = read_conloc(hw);
    if(absFast<absSlow)
        %     warning('slow delay cannot get greater value than fast delay,raising fast delay');
        absFast=absSlow;
    end
end

regs=writeAbsVals(hw,absFast,absSlow);
hw.runPresetScript('maRestart');
end

function v=read_conloc(hw)
v=hw.read('EXTLconLocDelayFastF')+hw.read('EXTLconLocDelayFastC');
end

function v=read_latelate(hw)
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

absFast = uint32(absFast);
absSlow = uint32(absSlow);
latelate = absFast-absSlow;

regs.EXTL.conLocDelaySlow = uint32(latelate)+uint32(bitshift(1,31));
mod8=mod(absFast,8);
regs.EXTL.conLocDelayFastC= uint32(absFast-mod8);
regs.EXTL.conLocDelayFastF=uint32(mod8);
hw.write('EXTLconLocDelaySlow',regs.EXTL.conLocDelaySlow);
hw.write('EXTLconLocDelayFastC',regs.EXTL.conLocDelayFastC);
hw.write('EXTLconLocDelayFastF',regs.EXTL.conLocDelayFastF);
end

