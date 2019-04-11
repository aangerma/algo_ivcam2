function [  ] = setTKillValues(hw,calibParams,fprintff)

cmd = sprintf('CT_KILL_THRESHOLDS_SET %s %s %s %s',asStr(calibParams.gnrl.lddTKill),asStr(calibParams.gnrl.mcTKill),asStr(calibParams.gnrl.maTKill),asStr(calibParams.gnrl.apdTKill));
hw.cmd(cmd);
fprintff('Temperature kill command: %s\n',cmd);

end

function str = asStr(value)
    
if isempty(value)
   str = 'ff';
else
   str = dec2hex(value,2);
end

end

