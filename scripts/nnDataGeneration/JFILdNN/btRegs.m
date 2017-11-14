function [ regs ] = btRegs( regs )
%BTREGS loads the regs file exported from tensorflow and configure it the
%the regs struct.
exportedRegs = load('X:\Data\IvCam2\NN\JFIL\BilateralRegs\trainedBiltRegs_comb.mat');
exportedRegs = exportedRegs.bilt_regs;
regs.JFIL.biltConfThr = uint8(exportedRegs.biltConfThr);
regs.JFIL.biltSharpnessS = uint8(exportedRegs.sdSharpness);
% regs.JFIL.biltConfAdaptR = ?
% regs.JFIL.biltConfAdaptS = ?
regs.JFIL.biltDepthAdaptS = uint8(exportedRegs.depthAdaptS);
regs.JFIL.biltGauss = uint8(exportedRegs.gaussVars(:));
regs.JFIL.biltSigmoid = uint8(exportedRegs.sigmoid);

% Try to minimize the quantization error of the sharpness. It is multiplied
% by the depthAdaptR so the multipication should be as close as possible to
% the quantized value.
gt = [exportedRegs.rdSharpness1*exportedRegs.depthAdaptR;
        exportedRegs.rdSharpness2*exportedRegs.depthAdaptR;
        exportedRegs.rdSharpness3*exportedRegs.depthAdaptR;
             ];
sFact = 0.00:0.1:63;
for i = 1:length(sFact)
    trial.(strcat('c',num2str(i))) = single([uint8(sFact(i)*exportedRegs.rdSharpness1)*uint8(exportedRegs.depthAdaptR/sFact(i));
                                             uint8(sFact(i)*exportedRegs.rdSharpness2)*uint8(exportedRegs.depthAdaptR/sFact(i));
                                             uint8(sFact(i)*exportedRegs.rdSharpness3)*uint8(exportedRegs.depthAdaptR/sFact(i))]);
end
err = zeros(1,length(sFact));
for i = 1:length(sFact)
    err(i) = norm(trial.(strcat('c',num2str(i)))-gt);
end
[~,i_min] = min(err);

regs.JFIL.bilt1SharpnessR = uint8(exportedRegs.rdSharpness1*sFact(i_min));
regs.JFIL.bilt2SharpnessR = uint8(exportedRegs.rdSharpness2*sFact(i_min));
regs.JFIL.bilt3SharpnessR = uint8(exportedRegs.rdSharpness3*sFact(i_min));
regs.JFIL.biltDepthAdaptR = uint8(exportedRegs.depthAdaptR/sFact(i_min));






end

