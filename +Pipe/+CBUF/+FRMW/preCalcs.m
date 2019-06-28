function [regs,autogenRegs,autogenLuts] = preCalcs(regs,luts,autogenRegs,autogenLuts)
% Create regs for CBUF x sections according to calibration resolution
sectionVecRegs.FRMW.cbufxSections = typecast(calcCbufSection(regs,luts), 'uint32');
autogenRegs = Firmware.mergeRegs(autogenRegs,sectionVecRegs);
regs = Firmware.mergeRegs(regs,autogenRegs);
end



function [sectionVec] = calcCbufSection(regs,luts)
NUM_SECTIONS = single(124);
ANG_STEP = 8;

dXpix = single(regs.FRMW.calImgHsize)/NUM_SECTIONS; % Delta pixel between sections on x axis 
xPix = 1:dXpix:single(regs.FRMW.calImgHsize);
num_of_samples = length(xPix); % Sampled x pixels that are transformed to the angle domain

v = Calibration.aux.xy2vec(xPix,ones(num_of_samples,1)*single(regs.FRMW.calImgVsize)*0.5,regs); % for each pixel, get the unit vector in space corresponding to it.
[angX,angY] = Calibration.aux.vec2ang(v,regs);
angxPrePolyUndist = Calibration.Undist.inversePolyUndistAndPitchFix(angX,angY,regs);
[angYgrid,angXgrid] = ndgrid(single(-2^11-1:ANG_STEP:2^11-1),angxPrePolyUndist); % Creating a grid in the angle domain along the scan lines
[angxPostPolyUndist, angyPostPolyUndist] = Calibration.Undist.applyPolyUndistAndPitchFix(angXgrid,angYgrid,regs);
[xF,yF] = Calibration.aux.vec2xy(Calibration.aux.ang2vec(angxPostPolyUndist,angyPostPolyUndist,regs), regs); % Return to the image domain to look for maximal scan line width in each of the NUM_SECTIONS sections 
xF = reshape(xF,size(angXgrid));
yF = reshape(yF,size(angYgrid));

% Masking points on scanline that are out of the image
roiMask = (yF>=0 & yF<regs.FRMW.calImgVsize );
xF(~roiMask)=nan;

sectionVec = max(ceil(nanmax_(xF)-nanmin_(xF)),0);
end
