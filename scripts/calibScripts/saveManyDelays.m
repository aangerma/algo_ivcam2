function [frames] = saveManyDelays(hw)

hw.setReg('RASTbiltBypass'     ,true);
hw.setReg('RASTbiltSharpnessR'     ,uint8(0));
hw.setReg('RASTbiltSharpnessS'     ,uint8(0));
hw.setReg('JFILbypass$'         ,false);
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
hw.setReg('JFILsort1bypassMode',uint8(0));
hw.setReg('JFILsort2bypassMode',uint8(0));
hw.setReg('JFILsort3bypassMode',uint8(1));
hw.setReg('JFILupscalexyBypass',true);
hw.setReg('JFILgammaBypass'    ,false);
hw.setReg('DIGGsphericalEn',true);
%hw.cmd('mwd a0020c00 a0020c04 01E00320 // DIGGsphericalScale'); % 01E00280
%hw.cmd('mwd a0020bfc a0020c00 00f005E0 // DIGGsphericalOffset'); % 00f00500
hw.shadowUpdate();



initSlowDelay = bitand(hw.readAddr('a0060008'), hex2dec('7FFFFFFF'));
Calibration.aux.hwSetDelay(hw, 128, false);

% slow delay should be set to 128 and calibrated
initFastDelay = double(hw.readAddr('a0050548') + hw.readAddr('a0050458'));
fastDelay = initFastDelay + 128 - initSlowDelay;
Calibration.aux.hwSetDelay(hw, fastDelay, true);

delays = fastDelay-120:4:fastDelay+120;
%delays = 29000:4:29100;
nDelays = length(delays);

frames = cell(nDelays, 4);

for i=1:nDelays
    delay = delays(i);
    Calibration.aux.hwSetDelay(hw, delay, true);
    
    slowDelay = 128 + delay - fastDelay;
    Calibration.aux.hwSetDelay(hw, slowDelay, false);

    hw.setReg('DESTaltIrEn', false);
    hw.shadowUpdate();
    frames{i, 1} = hw.getFrame(30);

    hw.setReg('DESTaltIrEn', true);
    hw.shadowUpdate();

    frames{i,4} = hw.getFrame(30);
    [frames{i,2}, frames{i,3}] = getFrameTwoDirs(hw,30);
    
    figure(11711); 
    subplot(2,2,1); imagesc(frames{i,1}.i);
    subplot(2,2,3); imagesc(frames{i,2}.i);
    subplot(2,2,4); imagesc(frames{i,3}.i);
    subplot(2,2,2); imagesc(frames{i,4}.i);
    tStr = sprintf('Changing delays : %u (%u of %u)', delay, i, nDelays);
    title(tStr);
    drawnow;
end

hw.setReg('DESTaltIrEn', false);
hw.shadowUpdate();

Calibration.aux.hwSetDelay(hw, initSlowDelay, false);
Calibration.aux.hwSetDelay(hw, initFastDelay, true);

% back to default spherical
%hw.cmd('mwd a0020c00 a0020c04 01E00280 // DIGGsphericalScale');
%hw.cmd('mwd a0020bfc a0020c00 00f00500 // DIGGsphericalOffset');
%hw.shadowUpdate();

end

