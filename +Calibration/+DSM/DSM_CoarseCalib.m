function dsmregs = DSM_CoarseCalib(hw,calibParams,runParams)
% Set regs such that -angmax,+angmax will cover the entire image
% Look at the image, calculate the true angle range and set the scale and
% offset accordingly.

[angxRaw, angyRaw] = DSM_CoarseCalib_init(hw,calibParams.coarseDSM.nSamples);

% DSM_CoarseCalib_grabe no need

ff = Calibration.aux.invisibleFigure();
plot(angxRaw,angyRaw,'r*'); xlabel('angxRaw'); ylabel('angyRaw'); title('Coarse DSM inputs');
Calibration.aux.saveFigureAsImage(ff,runParams,'Coarse_DSM','Inputs_Distribution');

[DSM_data] = DSM_CoarseCalib_Calc(angxRaw, angyRaw ,calibParams);

dsmregs = DSM_CoarseCalib_Output(hw,DSM_data);

end


function [angxRaw, angyRaw] = DSM_CoarseCalib_init(hw,nSamples)
    % prepare vectors of angx and angy samples as input for DSM coarse calibration 
    [angxRaw, angyRaw] = Calibration.DSM.memsRawData(hw,nSamples);
end

function dsmregs = DSM_CoarseCalib_Output(hw,DSM_data)
% matlab tool 
    dsmregs.EXTL.dsmXscale  = DSM_data.dsmXscale;
    dsmregs.EXTL.dsmXoffset = DSM_data.dsmXoffset;
    dsmregs.EXTL.dsmYscale  = DSM_data.dsmYscale;
    dsmregs.EXTL.dsmYoffset = DSM_data.dsmYoffset;

% converet DSM_data to register set
    hw.setReg('EXTLdsmXscale' ,dsmregs.EXTL.dsmXscale);
    hw.setReg('EXTLdsmYscale' ,dsmregs.EXTL.dsmYscale);
    hw.setReg('EXTLdsmXoffset',dsmregs.EXTL.dsmXoffset);
    hw.setReg('EXTLdsmYoffset',dsmregs.EXTL.dsmYoffset);
    hw.shadowUpdate;
end

