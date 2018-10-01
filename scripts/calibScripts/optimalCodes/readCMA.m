function [cma,cmaSTD] = readCMA(hw)

tmplLength = double(hw.read('GNRLtmplLength'));
hw.setReg('JFILbypass$', true);    
hw.setReg('DCORoutIRcma$', true);

frame = hw.getFrame();
imSize = size(frame.i);

cma = zeros([tmplLength imSize], 'uint8');
cmaSTD = zeros([tmplLength imSize], 'uint8');

for iCMA = (1:tmplLength)-1
    %hw.setReg('DCORoutIRcmaIndex', [uint8(floor(iCMA/84)) uint8(floor(mod(iCMA,84)))]);
    strCmdIndex = 'mwd a00208c8 a00208cc 0000%02x%02x // DCORoutIRcmaIndex';
    hw.cmd(sprintf(strCmdIndex, uint8(floor(mod(iCMA,84))), uint8(floor(iCMA/84))));
    hw.shadowUpdate();

    [cmaBin, cmaST] = getBin(hw, 2, imSize);
    cma(iCMA+1,:,:) = cmaBin;
    cmaSTD(iCMA+1,:,:) = cmaST;

    tStr = sprintf('Bin %u of %u.\n', iCMA, tmplLength);
    figure(11711);        
    imagesc(cmaBin);colorbar;
    title(tStr);
%     fprintf(tStr);
    drawnow;
end
hw.setReg('DCORoutIRcma$', false);
end

function [cmaBin, cmaSTD] = getBin(hw, nExp, imSize)
nFrames= 2^nExp;
cmaA = zeros([imSize,nFrames]);
for i=1:nFrames
    frame = hw.getFrame();
    cmaA(:,:,i) = double(frame.i);
    
end
cmaA(cmaA==0) = nan;
cmaBin = uint8(mean(cmaA * 4,3,'omitnan' ));
cmaSTD = std(cmaA * 4,[],3,'omitnan' );

end
