function [regs,autogenRegs,autogenLuts] = preCalcs(regs,luts,autogenRegs,autogenLuts)
% Create a LUT for CBUF x sections according to calibration resolution
sectionVecLut.CBUF.xSections = typecast(calcCbufSection(regs), 'uint32');
autogenLuts = Firmware.mergeRegs(autogenLuts,sectionVecLut);
end



function [sectionVec] = calcCbufSection(regs)
NUM_SECTIONS = 128;
MIN_BUFFER_SIZE = 8; %Get rid of this!
ANG_STEP = 8;

dXpix = regs.FRMW.calImgHsize/NUM_SECTIONS; % Delta pixel between sections on x axis 
xPix = 1:dXpix:regs.FRMW.calImgHsize;
num_of_samples = length(xPix); % Sampled x pixels that are transformed to the angle domain
[angX,~] = Calibration.aux.xy2angSF(xPix,ones(num_of_samples,1)*regs.FRMW.calImgVsize /2,regs,true);
[angYgrid,angXgrid] = ndgrid(int16(-2^11-1:ANG_STEP:2^11-1),angX); % Creating a grid in the angle domain along the scan lines
[xF,yF] = Calibration.aux.ang2xySF(angXgrid,angYgrid,regs,[],true); % Return to the image domain to look for maximal scan arch in each of the NUM_SECTIONS sections 

% Masking points on scanline that are out of the image
roiMask = (yF>=0 & yF<regs.FRMW.calImgVsize );
xF(~roiMask)=nan;

sectionVec = max(ceil(nanmax_(xF)-nanmin_(xF)),MIN_BUFFER_SIZE);
end

%{
regs.FRMW.calImgHsize = 640;
regs.FRMW.calImgVsize = 360;
%}