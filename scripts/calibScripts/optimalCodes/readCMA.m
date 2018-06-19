function cma = readCMA(hw)

tmplLength = double(hw.read('GNRLtmplLength'));
hw.setReg('JFILbypass$', true);    
hw.setReg('DCORoutIRcma$', true);

frame = hw.getFrame();
imSize = size(frame.i);

cma = zeros([tmplLength imSize], 'uint8');

for iCMA = (1:tmplLength)-1
    %hw.setReg('DCORoutIRcmaIndex', [uint8(floor(iCMA/84)) uint8(floor(mod(iCMA,84)))]);
    strCmdIndex = 'mwd a00208c8 a00208cc 0000%02x%02x // DCORoutIRcmaIndex';
    hw.cmd(sprintf(strCmdIndex, uint8(floor(mod(iCMA,84))), uint8(floor(iCMA/84))));
    hw.shadowUpdate();

    [cmaBin, cmaC] = getBin(hw, 6, imSize);
    cma(iCMA+1,:,:) = cmaBin;


    figure(11711);        
    subplot(1,2,1); imagesc(cmaBin);
    subplot(1,2,2); imagesc(cmaC);
    tStr = sprintf('Bin %u of %u', iCMA, tmplLength);
    subplot(1,2,1); title(tStr);
    drawnow;
end

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
