function [regs,autogenRegs,autogenLuts] = preCalcs(regs,luts,autogenRegs,autogenLuts)
% Create regs for CBUF x sections according to calibration resolution
sectionVecRegs.CBUF.xSections = typecast(calcCbufSection(regs), 'uint32');
autogenRegs = Firmware.mergeRegs(autogenRegs,sectionVecRegs);
regs = Firmware.mergeRegs(regs,autogenRegs);
end



function [sectionVec] = calcCbufSection(regs)
NUM_SECTIONS = single(128);
ANG_STEP = 8;

dXpix = round(single(regs.FRMW.calImgHsize)/NUM_SECTIONS); % Delta pixel between sections on x axis 
xPix = 1:dXpix:single(regs.FRMW.calImgHsize);
num_of_samples = length(xPix); % Sampled x pixels that are transformed to the angle domain
[angX,~] = Calibration.aux.xy2angSF(xPix,ones(num_of_samples,1)*single(regs.FRMW.calImgVsize)*0.5,regs,true);
angxPrePolyUndist = Calibration.Undist.inversePolyUndist(angX,regs);
[angYgrid,angXgrid] = ndgrid(int16(-2^11-1:ANG_STEP:2^11-1),angxPrePolyUndist); % Creating a grid in the angle domain along the scan lines
angxPostPolyUndist = Calibration.Undist.applyPolyUndist(angXgrid,regs);
[xF,yF] = Calibration.aux.ang2xySF(angxPostPolyUndist,angYgrid,regs,[],true); % Return to the image domain to look for maximal scan arch in each of the NUM_SECTIONS sections 

% Masking points on scanline that are out of the image
roiMask = (yF>=0 & yF<regs.FRMW.calImgVsize );
xF(~roiMask)=nan;

sectionVec = max(ceil(nanmax_(xF)-nanmin_(xF)),0);
end
