function [frames] = saveCMAsDelays(hw)

if hw.read('GNRLsampleRate') ~= 8
    error('Only sample rate of 8 is supported');
end

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

dRange = 128;
delays = fastDelay-dRange:4:fastDelay+dRange;
%delays = 29000:4:29100;
nDelays = length(delays);

frames = cell(nDelays, 5);

tmplLength = double(hw.read('GNRLtmplLength'));

%byteToBoolLut = typecast(vec(flipud(int8((dec2bin((0:255)')-48)~=0)')),'uint64');

frame = hw.getFrame();
imSize = size(frame.i);

hwSetScanDir(hw, 2);

for i=1:nDelays
    delay = delays(i);
    Calibration.aux.hwSetDelay(hw, delay, true);
    
    slowDelay = 128 + delay - fastDelay;
    Calibration.aux.hwSetDelay(hw, slowDelay, false);

    hw.setReg('JFILbypass$', false);
    hw.setReg('DCORoutIRcma$', false);
    hw.shadowUpdate();
    hwSetScanDir(hw, 2);
    frames{i,1} = hw.getFrame(30); % ir frame
    hwSetScanDir(hw, 0);
    frames{i,2} = hw.getFrame(30); % ir frame
    hwSetScanDir(hw, 1);
    frames{i,3} = hw.getFrame(30); % ir frame

    cma0 = zeros([tmplLength size(frames{i,1}.i)], 'uint8');
    cma1 = zeros([tmplLength size(frames{i,1}.i)], 'uint8');
    for iCMA = (1:tmplLength)-1
        hw.setReg('JFILbypass$', true);    
        hw.setReg('DCORoutIRcma$', true);
        
        %hw.setReg('DCORoutIRcmaIndex', [uint8(floor(iCMA/84)) uint8(floor(mod(iCMA,84)))]);
        
      
        strCmdIndex = 'mwd a00208c8 a00208cc 0000%02x%02x // DCORoutIRcmaIndex';
        hw.cmd(sprintf(strCmdIndex, uint8(floor(mod(iCMA,84))), uint8(floor(iCMA/84))));
        hw.shadowUpdate();

        hwSetScanDir(hw, 0);
        [cmaBin0, cmaC0] = getBin(hw, 6, imSize);
        cma0(iCMA+1,:,:) = cmaBin0;

        hwSetScanDir(hw, 1);
        [cmaBin1, cmaC1] = getBin(hw, 6, imSize);
        cma1(iCMA+1,:,:) = cmaBin1;

        figure(11711);        
        subplot(2,2,1); imagesc(cmaBin0);
        subplot(2,2,3); imagesc(cmaBin1);
        subplot(2,2,2); imagesc(cmaC0);
        subplot(2,2,4); imagesc(cmaC1);
        tStr = sprintf('Delays %u of %u, bin %u of %u', i, nDelays, iCMA, tmplLength);
        subplot(2,2,1); title(tStr);
        drawnow;
    end
    frames{i,4} = cma0;
    frames{i,5} = cma1;
    
    %{
    figure(11711); 
    subplot(2,2,1); imagesc(frames{i,1}.i);
    subplot(2,2,3); imagesc(frames{i,2}.i);
    subplot(2,2,4); imagesc(frames{i,3}.i);
    subplot(2,2,2); imagesc(frames{i,4}.i);
    tStr = sprintf('Changing delays : %u (%u of %u)', delay, i, nDelays);
    title(tStr);
    drawnow;
    %}
end

hw.setReg('DCORoutIRcma$', false);
hw.setReg('JFILbypass$', false);
hw.shadowUpdate();
hwSetScanDir(hw, 2);

Calibration.aux.hwSetDelay(hw, initSlowDelay, false);
Calibration.aux.hwSetDelay(hw, initFastDelay, true);

% back to default spherical
%hw.cmd('mwd a0020c00 a0020c04 01E00280 // DIGGsphericalScale');
%hw.cmd('mwd a0020bfc a0020c00 00f00500 // DIGGsphericalOffset');
%hw.shadowUpdate();

end

function [cmaBin, cmaC] = getBin(hw, nExp, imSize)

cmaA = zeros(imSize);
cmaC = zeros(imSize);



for i=1:2^nExp
    frame = hw.getFrame();
    cmaA = cmaA + double(frame.i);
    cmaC = cmaC + double(frame.z ~= 0);
end

cmaBin = uint8(cmaA * 4 ./ cmaC);
cmaC = uint8(cmaC);

end


