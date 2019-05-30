function [regs,autogenRegs,autogenLuts] = preCalcs(regs,luts,autogenRegs,autogenLuts)
% Create regs for CBUF x sections according to calibration resolution
sectionVecRegs.FRMW.cbufxSections = typecast(calcCbufSection(regs,luts), 'uint32');
autogenRegs = Firmware.mergeRegs(autogenRegs,sectionVecRegs);
regs = Firmware.mergeRegs(regs,autogenRegs);
end



function [sectionVec] = calcCbufSection(regs,luts)
NUM_SECTIONS = single(124);
ANG_STEP = 8;
FE = [];
if regs.FRMW.fovExpanderValid
    FE = Utils.feVec2Mat(regs,luts);
end

dXpix = single(regs.FRMW.calImgHsize)/NUM_SECTIONS; % Delta pixel between sections on x axis 
xPix = 1:dXpix:single(regs.FRMW.calImgHsize);
num_of_samples = length(xPix); % Sampled x pixels that are transformed to the angle domain
reg_FE_inv = regs;
if isempty(FE)
[angX,~] = Calibration.aux.xy2angSF(xPix,ones(num_of_samples,1)*single(regs.FRMW.calImgVsize)*0.5,regs,true);
else
    reg_FE_inv.FRMW.xfov = interp1(FE(:,2),FE(:,1),regs.FRMW.xfov/2)*2;% Inverse (undo) to FOV expander which was added to regs in 'calibUndistAng2xyBugFix' before this function
    reg_FE_inv.FRMW.yfov = interp1(FE(:,2),FE(:,1),regs.FRMW.yfov/2)*2; 
    v = Calibration.aux.xy2vec(xPix,ones(num_of_samples,1)*single(regs.FRMW.calImgVsize)*0.5,regs); % for each pixel, get the unit vector in space corresponding to it.
    [angX,~] = Calibration.aux.vec2ang(v,reg_FE_inv,FE);
end
angxPrePolyUndist = Calibration.Undist.inversePolyUndist(angX,regs);
[angYgrid,angXgrid] = ndgrid(int16(-2^11-1:ANG_STEP:2^11-1),angxPrePolyUndist); % Creating a grid in the angle domain along the scan lines
angxPostPolyUndist = Calibration.Undist.applyPolyUndist(angXgrid,regs);
[xF,yF] = Calibration.aux.ang2xySF(angxPostPolyUndist,angYgrid,reg_FE_inv,FE,true); % Return to the image domain to look for maximal scan line width in each of the NUM_SECTIONS sections 

% Masking points on scanline that are out of the image
roiMask = (yF>=0 & yF<regs.FRMW.calImgVsize );
xF(~roiMask)=nan;

sectionVec = max(ceil(nanmax_(xF)-nanmin_(xF)),0);
end
