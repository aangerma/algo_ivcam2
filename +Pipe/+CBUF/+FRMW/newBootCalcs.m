function [regs,autogenRegs,autogenLuts] = newBootCalcs(regs,luts,autogenRegs,autogenLuts)
%% CBUF calcs
maxBufferSize = getMaxBufferSize(regs.GNRL.imgVsize);
MIN_BUFFER_SIZE = 8; %Get rid of this!

MAX_NUM_SECTIONS = 16;

if regs.FRMW.fovExpanderValid
    % Create LUT of entry angle vs. exit angle in case of unit with FOV expander
    fovExpanderLut = createFeLut();
    autogenLuts = Firmware.mergeRegs(autogenLuts,fovExpanderLut);
end

autogenRegs.CBUF.xBitShifts =uint8(ceil(log2(double(regs.GNRL.imgHsize-1)))-4);
num_sections =  bitshift(double(regs.GNRL.imgHsize-1),-int16(autogenRegs.CBUF.xBitShifts))+1;
assert(num_sections<=MAX_NUM_SECTIONS);
if(regs.FRMW.cbufConstLUT || regs.GNRL.rangeFinder)
    xSecPixLgth = ones(1,16)*(maxBufferSize);
else
    xcrossPix = bitshift((0:n-1),autogenRegs.CBUF.xBitShifts);
    
    
end
end


function [maxBufferSize] = getMaxBufferSize(imgVsize)
if(imgVsize>=721)
    maxBufferSize=64;
elseif(regs.GNRL.imgVsize>=513)
    maxBufferSize=85;
else
    maxBufferSize=120;
end
maxBufferSize = min(maxBufferSize,double(regs.GNRL.imgHsize-1));
BUFFER_TOP_MARGIN=10;

maxBufferSize = maxBufferSize-BUFFER_TOP_MARGIN;
end

function [sectionVec] = calcCbufSection(regs)
NUM_SECTIONS = 128;
MIN_BUFFER_SIZE = 8; %Get rid of this!

ANG_STEP = 8;
dXpix = regs.FRMW.CalImgVsize/NUM_SECTIONS;
xPix = 1:dXpix:regs.FRMW.CalImgVsize;
num_of_samples = length(xPix);
% x = reshape(repmat(xPix,1,3)', [],1);
% y = [ones(num_of_samples,1); ones(num_of_samples,1)*regs.FRMW.CalImgHsize /2; ones(num_of_samples,1)*regs.FRMW.CalImgHsize ];
[angX,~] = Calibration.aux.xy2angSF(xPix,ones(num_of_samples,1)*regs.FRMW.CalImgHsize /2,regs,true);
[angYgrid,angXgrid] = ndgrid(int16(-2^11-1:ANG_STEP:2^11-1),angX);
[xF,yF] = Calibration.aux.ang2xySF(angXgrid,angYgrid,regs,[],true);


roiMask = (yF>=0 & yF<regs.FRMW.CalImgHsize );
xF(~roiMask)=nan;

sectionVec = max(ceil(nanmax_(xF)-nanmin_(xF)),MIN_BUFFER_SIZE);
end

%{
regs.FRMW.CalImgHsize = 360;
regs.FRMW.CalImgVsize = 640;
%}


