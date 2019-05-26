function [regs,autogenRegs,autogenLuts] = fwBootCalcs(regs,luts,autogenRegs,autogenLuts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function calculates the distances (in pixels) along the x axis
% between the read and write pointer of the CBUF block.
% This function should be re-calculated when one of the following variables changes: 
% -----------------------------------
% Regs from EPROM: 
% -----------------------------------
% autogenRegs.EXTL.cbufMemBufSz, regs.FRMW.calImgHsize,
% autogenRegs.CBUF.xRelease, autogenRegs.EXTL.cbufValPer
% -----------------------------------
% Regs from external configuration:
% -----------------------------------
% regs.GNRL.imgHsize, regs.GNRL.imgVsize, autogenRegs.CBUF.xBitShifts, regs.FRMW.cbufConstLUT,
% regs.GNRL.rangeFinder, regs.JFIL.upscalexyBypass, regs.FRMW.cropXfactor, regs.FRMW.cropYfactor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
autogenRegs.FRMW.cbufxSections=regs.FRMW.cbufxSections; % copy to hw
xSections = calcXsections(regs);

autogenRegs.CBUF.xBitShifts = uint8(ceil(log2(double(regs.GNRL.imgHsize-1)))-4);
num_sections =  bitshift(double(regs.GNRL.imgHsize-1),-int16(autogenRegs.CBUF.xBitShifts))+1;
assert(num_sections <= getMaxNumSections);
xcrossPix = bitshift((0:num_sections-1),autogenRegs.CBUF.xBitShifts); % The division of the x axis up to getMaxNumSections of sections where the maximal scanline width will be calculated

if(regs.FRMW.cbufConstLUT || regs.GNRL.rangeFinder)
%     All sections are equal and get the maximal value of xSections
    xSecPixLgth = single(ones(1,num_sections))*(max(xSections) + single(regs.FRMW.cbufMargin));
else
%     Calculate the buffer size by finding the maximal values in xSections for each range determined by xcrossPix
    dPixInXsections = single(regs.GNRL.imgHsize)/single(length(xSections));
    xSecPixLgth = single(zeros(1,num_sections));
    xSecIxStart = 1;
    MAX_BUFFER_SIZE = getMaxBufferSize(regs);
    for k = 2:num_sections
        xSecIxEnd = min(ceil(xcrossPix(k)/dPixInXsections) + 1, length(xSections)); 
        xSecPixLgth(k-1) = min(max(xSections(xSecIxStart:xSecIxEnd))+ single(regs.FRMW.cbufMargin), MAX_BUFFER_SIZE);
        xSecIxStart = max(1, xSecIxEnd - 2);
    end
    xSecPixLgth(num_sections) = min(max([xSections(xSecIxStart:end),0])+ single(regs.FRMW.cbufMargin), MAX_BUFFER_SIZE);
end
autogenRegs.CBUF.xRelease = uint16(zeros(1,getMaxNumSections));
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
function [xSections] = calcNewSectionsForXcrop(regs,xSections )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% In case of X cropping the distance between sampling does not change and
% also the maxmium scanline arch in each section does not change.
% The range of the sections we are looking at changes according to crop.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
resXafterCrop = regs.FRMW.cropXfactor*single(regs.FRMW.calImgHsize);
resDiff = single(regs.FRMW.calImgHsize) - resXafterCrop;
startXfromCalib = resDiff*0.5 + 1.0;
endXfromCalib = startXfromCalib + resXafterCrop - 1.0;
if nargin == 2
    originalXsectionsRegs = single(xSections);
else
    originalXsectionsRegs = typecast(regs.FRMW.cbufxSections, 'single');
end
dPixInLUT = single(regs.FRMW.calImgHsize)/single(length(originalXsectionsRegs));
ix_start = max(round(startXfromCalib/dPixInLUT),1);
ix_end = min(round(endXfromCalib/dPixInLUT), length(originalXsectionsRegs));
xSections = originalXsectionsRegs(ix_start:ix_end);
end

function [xSections] = calcNewSectionsForYcrop(regs,xSections)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% In case of Y cropping the distance between sampling does not change but
% the maxmium scanline arch in each section is scaled dowm the factor.
% The range of the sections we are looking at does not change.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin == 2
    originalXsectionsRegs = single(xSections);
else
    originalXsectionsRegs = typecast(regs.FRMW.cbufxSections, 'single');
end
xSections = single(ceil(originalXsectionsRegs.*regs.FRMW.cropYfactor));
end

function [xSections] = calcNewSectionsForXscale(regs,xSections)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% In case of X scale the distance between sampling changes and also
% the maxmium scanline arch in each section is scaled by the factor.
% The range of the sections we are looking at does not change.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%s
if nargin == 2
    originalXsectionsRegs = single(xSections);
else
    originalXsectionsRegs = typecast(regs.FRMW.cbufxSections, 'single');
end
scaleFactor = single(regs.GNRL.imgHsize)/(single(regs.FRMW.calImgHsize)*regs.FRMW.cropXfactor);
xSections = single(ceil(originalXsectionsRegs.*scaleFactor));
end

function [maxBufferSize] = getMaxBufferSize(regs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculating the maximum alowed buffer size for each section
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

function [maxNumSections] = getMaxNumSections()
maxNumSections = 16;
end

function [xSections] = calcXsections(regs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function calculates the new x sections that will determine the x releases for the CBUF.
% The calculation takes into account the scale and crop that might have
% been performed on the image since the regs.FRMW.cbufxSections was calculated
% in calibration.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xSections = typecast(regs.FRMW.cbufxSections, 'single');
if regs.GNRL.imgHsize ~= regs.FRMW.calImgHsize
    if regs.FRMW.cropXfactor < 1 % There was cropping in x
        xSections = calcNewSectionsForXcrop(regs);
    end
    if regs.FRMW.cropYfactor < 1 % There was cropping in y
        xSections = calcNewSectionsForYcrop(regs,xSections);
    end
    if round(single(regs.FRMW.calImgHsize)*regs.FRMW.cropXfactor) ~= regs.GNRL.imgHsize  % There was scaling in x (or x and y which is the same case here)
        xSections = calcNewSectionsForXscale(regs,xSections);
    end
end
end