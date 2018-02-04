function [regs,autogenRegs,autogenLuts] = bootCalcs(regs,luts,autogenRegs,autogenLuts)
%% CBUF calcs

if(regs.GNRL.imgVsize>=721)
    MAX_BUFFER_SIZE=64;
elseif(regs.GNRL.imgVsize>=513)
    MAX_BUFFER_SIZE=85;
else
    MAX_BUFFER_SIZE=120;
end
MAX_BUFFER_SIZE = min(MAX_BUFFER_SIZE,double(regs.GNRL.imgHsize-1));
BUFFER_TOP_MARGIN=10;

MAX_BUFFER_SIZE = MAX_BUFFER_SIZE-BUFFER_TOP_MARGIN;
MIN_BUFFER_SIZE = 8;

autogenRegs.CBUF.xBitShifts =uint8(ceil(log2(double(regs.GNRL.imgHsize-1)))-4);
n =  bitshift(double(regs.GNRL.imgHsize-1),-int16(autogenRegs.CBUF.xBitShifts))+1;
assert(n<=16);
if(regs.FRMW.cbufConstLUT || regs.GNRL.rangeFinder)
    lutData = ones(1,n)*(MAX_BUFFER_SIZE);
else
    %%
    xcrossPix = bitshift((0:n-1),autogenRegs.CBUF.xBitShifts);
    [xcrossAngQ,~] =  Pipe.CBUF.FRMW.xy2ang(xcrossPix,ones(size(xcrossPix))*double(regs.GNRL.imgVsize)/2,regs);
    angStep = 8;
    [angyQ,angxQ] = ndgrid(int16(-2^11-1:angStep:2^11-1),xcrossAngQ);
    [~,~,x,y] = Pipe.DIGG.ang2xy(angxQ,angyQ,regs,Logger(),[]);
    x = reshape(x,size(angxQ));
    y = reshape(y,size(angyQ));
    
    roiMask = (y>=0 & y<regs.GNRL.imgVsize);
    x(~roiMask)=nan;

%     lutData = max(x.*(y>=0 & y<regs.GNRL.imgVsize))-min(x+((y<0 | y>regs.GNRL.imgVsize)*10000))+1+MIN_BUFFER_SIZE;
     lutData = max(ceil(nanmax_(x)-nanmin_(x)),MIN_BUFFER_SIZE);
     lutData = min(lutData,MAX_BUFFER_SIZE);
    
end
% lutData
autogenRegs.CBUF.xRelease = uint16(zeros(1,16));
autogenRegs.CBUF.xRelease(1:n) = uint16(round(lutData));
%
%%ASIC
autogenRegs.CBUF.valPer=uint32(256);
if(~regs.JFIL.upscalexyBypass)
    autogenRegs.CBUF.valPer=uint32(512);
end
%%
regs = Firmware.mergeRegs(regs,autogenRegs);

if(0)
    %%
    figure(111222);plot(xPixCross,lutData);
    
end
end


% function x=movmax_(v,n)
%
% i=max(1,min(bsxfun(@plus,1:length(v),(0:n)'),numel(v)));
% x=max(v(i));
%
% end

