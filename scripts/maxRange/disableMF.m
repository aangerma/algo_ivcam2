function [  ] = disableMF( hw )
%DISABLEMF disables multi focal mode in AFE and PI

% disable in AFE
hw.cmd('mwd a0030228 a003022c 0 // Enable MultiFocal on AFE');
% disable in PI - shut down LSB
valstr = hw.cmd('mrd a0050620 a0050624 // Enable Multi Focal PI');
hexnum = valstr(end-7:end);
newval = dec2hex(hex2dec(hexnum)-mod(hex2dec(hexnum),2));

PI_MF_Cmd = strcat('mwd a0050620 a0050624',[' ',newval],' // Disable Multi Focal in the PI');
hw.cmd(PI_MF_Cmd);
hw.cmd('mwd a00d01f0 a00d01f4 ffffffff // Shadow update');
hw.cmd('mwd a00d01ec a00d01f0 ffffffff // Shadow update');





end

