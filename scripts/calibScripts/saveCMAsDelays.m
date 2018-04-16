function [frames] = saveCMAsDelays(hw)

if hw.read('GNRLsampleRate') ~= 8
    error('Only sample rate of 8 is supported');
end

hw.setReg('RASTbiltBypass'     ,true);
hw.setReg('RASTbiltSharpnessR'     ,uint8(0));
hw.setReg('RASTbiltSharpnessS'     ,uint8(0));
hw.setReg('JFILbypass$'         ,true);
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
hw.setReg('JFILgammaBypass'    ,true);
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

dRange = 0; %128;
delays = fastDelay-dRange:4:fastDelay+dRange;
%delays = 29000:4:29100;
nDelays = length(delays);

frames = cell(nDelays, 4);

tmplLength = double(hw.read('GNRLtmplLength'));

%byteToBoolLut = typecast(vec(flipud(int8((dec2bin((0:255)')-48)~=0)')),'uint64');

frame = hw.getFrame();
imSize = size(frame.i);

for i=1:nDelays
    delay = delays(i);
    Calibration.aux.hwSetDelay(hw, delay, true);
    
    slowDelay = 128 + delay - fastDelay;
    Calibration.aux.hwSetDelay(hw, slowDelay, false);

    hw.setReg('DCORoutIRcma$', false);
    hw.shadowUpdate();
    pause(0.2);
    frames{i,1} = hw.getFrame(30); % ir frame

    cma = zeros([tmplLength size(frames{i,1}.i)], 'uint8');
    for iCMA = (1:20)-1 %tmplLength
        hw.setReg('DCORoutIRcma$', true);
        strCmdIndex = 'mwd a00208c8 a00208cc 0000%02u%02u // DCORoutIRcmaIndex';
        %hw.setReg('DCORoutIRcmaIndex', [uint8(floor(iCMA/84)) uint8(floor(mod(iCMA,84)))]);
        hw.cmd(sprintf(strCmdIndex, uint8(floor(mod(iCMA,84))), uint8(floor(iCMA/84))));
        hw.shadowUpdate();
        pause(0.2);
        [cmaBin, imgBin] = getBin(hw, 0, imSize);
        cma(iCMA+1,:,:) = cmaBin;
        
        figure(11711);        
        imagesc(imgBin);
        tStr = sprintf('Delays %u of %u, bin %u of %u', i, nDelays, iCMA, tmplLength);
        title(tStr);
        drawnow;
    end
    frames{i,2} = cma;
    
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

Calibration.aux.hwSetDelay(hw, initSlowDelay, false);
Calibration.aux.hwSetDelay(hw, initFastDelay, true);

% back to default spherical
%hw.cmd('mwd a0020c00 a0020c04 01E00280 // DIGGsphericalScale');
%hw.cmd('mwd a0020bfc a0020c00 00f00500 // DIGGsphericalOffset');
%hw.shadowUpdate();

end

function [cmaBin, img] = getBin(hw, nExp, imSize)

cmaBin = zeros(imSize, 'uint16');



for i=1:2^nExp
    img = hw.getFrame().i;
    %frameCMAu64 = byteToBoolLut(img(:)+1);
    %bins = reshape(typecast(frameCMAu64,'uint8'), [8 imSize]);
    cmaBin = cmaBin + uint16(img);
end

cmaBin = bitshift(cmaBin, -nExp+2);

end


function [] = hwSetScanDir(hw, dir)

scanDir0gainAddr = '85080000';
scanDir1gainAddr = '85080480';
gainCalibValue  = '000ffff0';

global saveVal;
if isempty(saveVal)
    saveVal(1) = hw.readAddr(scanDir0gainAddr);
    saveVal(2) = hw.readAddr(scanDir1gainAddr);
end

if (dir == 0)
    hw.writeAddr(scanDir0gainAddr,gainCalibValue,true);
    hw.writeAddr(scanDir1gainAddr,saveVal(2),true);
elseif (dir == 1)
    hw.writeAddr(scanDir1gainAddr,gainCalibValue,true);
    hw.writeAddr(scanDir0gainAddr,saveVal(1),true);
elseif (dir == 2)
    hw.writeAddr(scanDir0gainAddr,saveVal(1),true);
    hw.writeAddr(scanDir1gainAddr,saveVal(2),true);
end

pause(0.15);

end

