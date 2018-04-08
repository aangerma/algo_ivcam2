function [frames] = saveManyDelays(hw)

hw.setReg('RASTbiltBypass'     ,false);
hw.setReg('RASTbiltSharpnessR'     ,uint8(0));
hw.setReg('RASTbiltSharpnessS'     ,uint8(0));
hw.setReg('JFILbypass'         ,false);
hw.setReg('JFILbilt1bypass'    ,true);
hw.setReg('JFILbilt2bypass'    ,true);
hw.setReg('JFILbilt3bypass'    ,true);
hw.setReg('JFILbiltIRbypass'   ,true);
hw.setReg('JFILdnnBypass'      ,true);
hw.setReg('JFILedge1bypassMode',uint8(1));
hw.setReg('JFILedge4bypassMode',uint8(1));
hw.setReg('JFILedge3bypassMode',uint8(1));
hw.setReg('JFILgeomBypass'     ,true);
hw.setReg('JFILgrad1bypass'    ,true);
hw.setReg('JFILgrad2bypass'    ,true);
hw.setReg('JFILirShadingBypass',true);
hw.setReg('JFILinnBypass'      ,true);
hw.setReg('JFILsort1bypassMode',uint8(1));
hw.setReg('JFILsort2bypassMode',uint8(1));
hw.setReg('JFILsort3bypassMode',uint8(1));
hw.setReg('JFILupscalexyBypass',true);
hw.setReg('JFILgammaBypass'    ,false);
hw.setReg('DESTaltIrEn'    ,true);
hw.setReg('DIGGsphericalEn',true);
hw.cmd('mwd a0020c00 a0020c04 01E00320 // DIGGsphericalScale'); % 01E00280
hw.cmd('mwd a0020bfc a0020c00 00f005E0 // DIGGsphericalOffset'); % 00f00500
hw.shadowUpdate();



f=figure('userdata',0,'KeyPressFcn',@(varargin) set(varargin{1},'userdata',1));
axis image; axis off;
colormap(gray(256));
title('Changing delays every fram');

delays = 28500:4:29500;
%delays = 28500:4:28520;
nDelays = length(delays);

frames = cell(nDelays, 1);

for i=1:nDelays
    delay = delays(i);
    Calibration.aux.hwSetDelay(hw, delay, true);
    
    frames{i} = hw.getFrame().i;
    imagesc(frames{i});
    axis equal
    tStr = sprintf('Changing delays : %u (%u of %u)', delay, i, nDelays);
    title(tStr);
    drawnow;
end

% back to default spherical
hw.cmd('mwd a0020c00 a0020c04 01E00280 // DIGGsphericalScale');
hw.cmd('mwd a0020bfc a0020c00 00f00500 // DIGGsphericalOffset');
hw.shadowUpdate();

end

