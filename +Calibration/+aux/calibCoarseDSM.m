function dsmregs = calibCoarseDSM(hw,calibParams,runParams)
% Set regs such that -angmax,+angmax will cover the entire image
% Look at the image, calculate the true angle range and set the scale and
% offset accordingly.
[angxRaw,angyRaw] = memsRawData(hw,calibParams.coarseDSM.nSamples);
[rawXmin,rawXmax] = minmax_(angxRaw);
[rawYmin,rawYmax] = minmax_(angyRaw);

ff = Calibration.aux.invisibleFigure();
plot(angxRaw,angyRaw,'r*'); xlabel('angxRaw'); ylabel('angyRaw'); title('Coarse DSM inputs');
Calibration.aux.saveFigureAsImage(ff,runParams,'Coarse_DSM','Inputs_Distribution');



[dsmregs.EXTL.dsmXscale,dsmregs.EXTL.dsmXoffset] = stretch2margin(rawXmin,rawXmax,calibParams.coarseDSM.margin);
[dsmregs.EXTL.dsmYscale,dsmregs.EXTL.dsmYoffset] = stretch2margin(rawYmin,rawYmax,calibParams.coarseDSM.margin);


hw.setReg('EXTLdsmXscale',dsmregs.EXTL.dsmXscale);
hw.setReg('EXTLdsmYscale',dsmregs.EXTL.dsmYscale);
hw.setReg('EXTLdsmXoffset',dsmregs.EXTL.dsmXoffset);
hw.setReg('EXTLdsmYoffset',dsmregs.EXTL.dsmYoffset);
hw.shadowUpdate;

% if verbose
%     r = Calibration.RegState(hw);
%     r.add('DIGGsphericalEn', true);
%     r.set();
%     frame = hw.getFrame(10);
%     imagesc(frame.i);
%     r.reset();
% end


end
function [scale,offset] = stretch2margin(rawMin,rawMax,margin)
target = 2047 - margin;
% scale*(rawMin+offset)-2047 = -target
% scale*(rawMax+offset)-2047 =  target

scale = single(2*target/(rawMax-rawMin));
offset = single((target+2047)/scale - rawMax);


end
function [angxRaw,angyRaw] = memsRawData(hw,nSamples)
    angyRaw = zeros(nSamples,1);
    angxRaw = zeros(nSamples,1);
    hw.cmd('mwd fffe2cf4 fffe2cf8 40');
    hw.cmd('mwd fffe2cf4 fffe2cf8 00');
    for i = 1:nSamples
        hw.cmd('mwd fffe2cf4 fffe2cf8 40');
        %  Read FA (float, 32 bits)
        [~,FA] = hw.cmd('mrd fffe882C fffe8830');
        angyRaw(i) = typecast(FA,'single');
        % Read SA (float, 32 bits)
        [~,SA] = hw.cmd('mrd fffe880C fffe8810');
        angxRaw(i) = typecast(SA,'single');
        hw.cmd('mwd fffe2cf4 fffe2cf8 00');
    end
    
end