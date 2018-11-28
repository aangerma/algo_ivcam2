function [  ] = setTxRateMF( hw, factor, LPFEn )
%SETTXRATEMF uses multi focal mode to change the tx/rx rate.
% Factor should be in [1,2,3,4]. LPFEn indices wheather to enable or
% disable AFE LPF.
% The unit will change to multifocal mode. The smallest ROI will be set to
% the entire image and the repetitions of the symbols will be set according
% to factor. The resulting tx frequency will be the original tx frequency (probably 1G) divided by factor. 
assert(any(factor==1:4),'setTxRateMF: Factor should be in [1,2,3,4]')
if ~exist('LPFEn','var')
    LPFEn = 1;
end
% hw.startStream();
hw.cmd('mwd a0030228 a003022c 1 // Enable MultiFocal on AFE');

PI_MF_Cmd = strcat('mwd a0050620 a0050624',[' 010',dec2hex(uint8(factor-1)),'0001'],' // Enable Multi Focal in the PI');
hw.cmd(PI_MF_Cmd);


AFE_LPF_Cmd = strcat('mwd a003006c a0030070',[' ',dec2hex(LPFEn)],' // Enable LPF in the AFE');
hw.cmd(AFE_LPF_Cmd); % Compare with and without LPF in the AFE. Seem to work better when it is not enabled. Worth testing.

% Small Rectangle bounderies are the entire frame  - take value from big
% frame
horizBigFov = hw.cmd('mrd a0050078 a005007c //Horizontal');
vertBigFov = hw.cmd('mrd a005007c a0050080 //Vertical');
smallRectHorizFov = horizBigFov(end-7:end);
smallRectVertFov = vertBigFov(end-7:end);

smallRectHCmd = strcat('mwd a0050094 a0050098',[' ',smallRectHorizFov]);
smallRectVCmd = strcat('mwd a0050098 a005009c',[' ',smallRectVertFov]);
hw.cmd(smallRectHCmd);
hw.cmd(smallRectVCmd);

hw.cmd('mwd a00d01f0 a00d01f4 ffffffff // Shadow update');
hw.cmd('mwd a00d01ec a00d01f0 ffffffff // Shadow update');


end

