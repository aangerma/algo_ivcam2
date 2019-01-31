function [regs,autogenRegs,autogenLuts] = fwBootCalcs(regs,luts,autogenRegs,autogenLuts)

%% =======================================DIGG - ang2xy- calib res =======================================
% Ang2xy is the transformation from angular data to rasterized grid over the projected plane.
%  The calculations produces:
%  *18 floating point coefficients for the runtime calculations (DIGG: nx,dx,ny,dy.)
%  *4 output registers for other blocks in the pipe: DIGG.angXfactor, DIGG.angYfactor.
%  2 parameters for firmware to save: FRMW.xres,FRMW.yres.
% Ang2xyCoeff function should be calculated when one of the following is changing: 
% Regs from EPROM: regs.FRMW.xfov, regs.FRMW.yfov, regs.FRMW.laserangleH,regs.FRMW.laserangleV,regs.FRMW.marginL/R/T/B, regs.FRMW.guardBandH,regs.FRMW.guardBandV, regs.FRMW.xR2L,regs.FRMW.xoffset, regs.FRMW.yoffset
%  Regs from external configuration: regs.GNRL.rangeFinder,regs.FRMW.mirrorMovmentMode, regs.FRMW.marginL/R/T/B, regs.FRMW.yflip,regs.GNRL.imgHsize,regs.GNRL.imgVsize  
autogenRegs.CBUF.xBitShifts = uint8(ceil(log2(double(regs.GNRL.imgHsize-1)))-4);
num_sections =  bitshift(double(regs.GNRL.imgHsize-1),-int16(autogenRegs.CBUF.xBitShifts))+1;
assert(num_sections <= maxNumSections);

xSections = typecast(autogenLuts.FRMW.cbufXsections, 'single');
if regs.FRMW.xres ~= regs.FRMW.calImgHsize
    if regs.FRMW.cropXfactor < 1 % There was cropping in x
        xSections = calcNewSectionsForXcrop(regs,regs.GNRL.imgHsize);
    end
    if regs.FRMW.cropYfactor < 1 % There was cropping in y
        xSections = calcNewSectionsForYcrop(regs,regs.GNRL.imgHsize,xSections);
    end
    if round(single(regs.FRMW.calImgHsize)*regs.FRMW.cropXfactor) ~= regs.GNRL.imgHsize  % There was scaling in x (or x and y which is the same case here)
        xSections = calcNewSectionsForXscale(regs,regs.GNRL.imgHsize,xSections);
    end
end
xcrossPix = bitshift((0:num_sections-1),autogenRegs.CBUF.xBitShifts);

if(regs.FRMW.cbufConstLUT || regs.GNRL.rangeFinder)
    xSecPixLgth = ones(1,num_sections)*max(xSections);
else
    dPix = xcrossPix(2) - xcrossPix(1);
    dPixInXsections = single(regs.GNRL.imgHsize)/single(length(xSections));
    xSecPixLgth = zeros(1,num_sections);
    xSecIxStart = 1;
    MAX_BUFFER_SIZE = getMaxBufferSize(regs);
    MIN_BUFFER_SIZE = getMinBufferSize;
    for k = 2:num_sections
        xSecIxEnd = min(ceil(xcrossPix(k)/dPixInXsections) + 1, length(xSections)); 
        xSecPixLgth(k-1) = max(xSections(xSecIxStart:xSecIxEnd));
        xSecIxStart = max(1, xSecIxEnd - 2);
    end
    xSecPixLgth(num_sections) = min(max([xSections(xSecIxStart:end),MIN_BUFFER_SIZE]), MAX_BUFFER_SIZE);
end
autogenRegs.CBUF.xRelease = uint16(zeros(1,16));
autogenRegs.CBUF.xRelease(1:numel(xSecPixLgth)) = uint16(round(xSecPixLgth));

%% ASIC

if(regs.GNRL.imgVsize>960)
    autogenRegs.EXTL.cbufMemBufSz=uint32(0);
elseif(regs.GNRL.imgVsize>720)
    autogenRegs.EXTL.cbufMemBufSz=uint32(1);
elseif(regs.GNRL.imgVsize>512)
    autogenRegs.EXTL.cbufMemBufSz=uint32(2);
else
    autogenRegs.EXTL.cbufMemBufSz=uint32(3);
end

autogenRegs.EXTL.cbufValPer=uint32(256);
if(~regs.JFIL.upscalexyBypass)
    autogenRegs.EXTL.cbufValPer=uint32(512);
end
%%
regs = Firmware.mergeRegs(regs,autogenRegs);

end


% -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
% -----------------------------------------------------------------------------------------------------------------------------------------------------------------------

% Helper Functios:
function [xSections] = calcNewSectionsForXcrop(regs,luts,xSections )
% In case of X cropping the distance between sampling does not change and
% also the maxmium scanline arch in each section does not change.
% The range of the sections we are looking at changes according to crop.
resXafterCrop = regs.FRMW.cropXfactor*single(regs.FRMW.calImgHsize);
resDiff = single(regs.FRMW.calImgHsize) - resXafterCrop;
startXfromCalib = resDiff*0.5 + 1.0;
endXfromCalib = startXfromCalib + resXafterCrop - 1.0;
if nargin == 3
    originalXsectionsLUT = single(xSections);
else
    originalXsectionsLUT = typecast(luts.FRMW.cbufXsections, 'single');
end
dPixInLUT = single(regs.FRMW.calImgHsize)/single(length(originalXsectionsLUT));
ix_start = max(round(startXfromCalib/dPixInLUT),1);
ix_end = min(round(endXfromCalib/dPixInLUT), length(originalXsectionsLUT));
xSections = originalXsectionsLUT(ix_start:ix_end);
end

function [xSections] = calcNewSectionsForYcrop(regs,luts,xSections)
% In case of Y cropping the distance between sampling does not change but
% the maxmium scanline arch in each section is scaled dowm the factor.
% The range of the sections we are looking at does not change.
if nargin == 3
    originalXsectionsLUT = single(xSections);
else
    originalXsectionsLUT = typecast(luts.FRMW.cbufXsections, 'single');
end
xSections = uint32(ceil(originalXsectionsLUT.*regs.FRMW.cropYfactor));
end

function [xSections] = calcNewSectionsForXscale(regs,luts,xSections)
% In case of X scale the distance between sampling changes and also
% the maxmium scanline arch in each section is scaled by the factor.
% The range of the sections we are looking at does not change.
if nargin == 3
    originalXsectionsLUT = single(xSections);
else
    originalXsectionsLUT = typecast(luts.FRMW.cbufXsections, 'single');
end
scaleFactor = single(regs.GNRL.imgHsize)/single(regs.FRMW.calImgHsize);
xSections = uint32(ceil(originalXsectionsLUT.*scaleFactor));
end

function [maxBufferSize] = getMaxBufferSize(regs)
if(regs.GNRL.imgVsize >= 721)
    maxBufferSize = 64;
elseif(regs.GNRL.imgVsize >= 513)
    maxBufferSize = 85;
else
    maxBufferSize = 120;
end
maxBufferSize = min(maxBufferSize,double(regs.GNRL.imgHsize-1));
BUFFER_TOP_MARGIN = 10;

maxBufferSize = maxBufferSize - BUFFER_TOP_MARGIN;
end

function [minBufferSize] = getMinBufferSize()
minBufferSize = 8;
end

function [maxNumSections] = getMaxNumSections()
MAX_NUM_SECTIONS = 16;
end