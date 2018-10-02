function cma = readCMA(obj,nAvg)

tmplLength = double(obj.read('GNRLtmplLength'));
obj.setReg('JFILbypass$', true);    
obj.setReg('DCORoutIRcma$', true);

frame = obj.getFrame();
imSize = size(frame.i);

cma = zeros([tmplLength imSize]);

for iCMA = (1:tmplLength)-1
    %hw.setReg('DCORoutIRcmaIndex', [uint8(floor(iCMA/84)) uint8(floor(mod(iCMA,84)))]);
    strCmdIndex = 'mwd a00208c8 a00208cc 0000%02x%02x // DCORoutIRcmaIndex';
    obj.cmd(sprintf(strCmdIndex, uint8(floor(mod(iCMA,84))), uint8(floor(iCMA/84))));
    obj.shadowUpdate();

    cmaBin = getBin(obj, nAvg, imSize);
    cma(iCMA+1,:,:) = cmaBin;

    tStr = sprintf('Bin %u of %u.\n', iCMA, tmplLength);
    figure(11711);        
    imagesc(cmaBin);colorbar;
    title(tStr);
%     fprintf(tStr);
    drawnow;
end
obj.setReg('DCORoutIRcma$', false);
end

function cmaBin = getBin(obj, nFrames, imSize)
cmaA = zeros([imSize,nFrames]);
for i=1:nFrames
    frame = obj.getFrame();
    frame.i = double(frame.i);
    frame.i(frame.z==0) = nan;
    cmaA(:,:,i) = double(frame.i);
    
end
cmaBin = (mean(cmaA * 4,3,'omitnan' ));

end
