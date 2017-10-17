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
MIN_BUFFER_SIZE = 25;

MAX_BUFFER_SIZE = MAX_BUFFER_SIZE-BUFFER_TOP_MARGIN;


autogenRegs.CBUF.xBitShifts =uint8(ceil(log2(double(regs.GNRL.imgHsize-1)))-4);
n =  bitshift(double(regs.GNRL.imgHsize-1),-int16(autogenRegs.CBUF.xBitShifts))+1;
assert(n<=16);
if(regs.FRMW.cbufConstLUT || regs.GNRL.rangeFinder)
    lutData = ones(1,n)*(MAX_BUFFER_SIZE);
else
    %%
    %using arbitrary frame rate
    fr = 60;%
    t=0:0.25/double(regs.EPTG.mirrorFastFreq):1/double(fr);
    angxIn  =  atand(tand(regs.FRMW.xfov/2) * (2 * double(fr) * t-1))/2;
    angyIn =@(f,phi)  -regs.FRMW.yfov/2/2*cos(2*pi*t*double(f)+phi); %fast
    angy = angyIn(regs.EPTG.mirrorFastFreq,0)+angxIn*regs.FRMW.projectionYshear;
    angx = angxIn + angyIn(regs.EPTG.mirrorFastFreq ,-regs.EPTG.slowCouplingFactor*pi/180)*regs.EPTG.slowCouplingFactor;
    if(regs.FRMW.xR2L)
        angx = -angx;
    end
    mm = @(x) max(-2047,min(2047,x));
    angxQ = mm(int16(round(angx/(regs.FRMW.xfov/2*.5)*(2^11-1))));
    angyQ = mm(int16(round(angy/(regs.FRMW.yfov/2*.5)*(2^11-1))));
    
    [~,~,xF,yF] = Pipe.DIGG.ang2xy(angxQ,angyQ,regs,Logger(),[]);
    
    curveSize = Pipe.CBUF.maxrun(double(xF))-xF;
    curveSize = movmax_(curveSize,2);
    curveSize =accumarray(min(double(regs.GNRL.imgHsize),max(1,round(xF+1))),curveSize',[regs.GNRL.imgHsize 1],@max);
    
    
    
    
    %     lutDataI=movmax_(lutDataI,ceil(length(lutDataI)/n));
    curveSize = movmax_(curveSize,2^double(autogenRegs.CBUF.xBitShifts+1));
    if(any(curveSize>MAX_BUFFER_SIZE))
        error('bad configuration! scan curve is too big');
    end
    xPixCross = bitshift((0:n-1),autogenRegs.CBUF.xBitShifts);
    
    lutData = interp1(0:double(regs.GNRL.imgHsize)-1,curveSize,xPixCross,'linear');
    lutData = max(lutData,MIN_BUFFER_SIZE);
end
% lutData
autogenRegs.CBUF.xRelease = uint16(zeros(1,16));
autogenRegs.CBUF.xRelease(1:n) = uint16(round(lutData));
%
regs = Firmware.mergeRegs(regs,autogenRegs);

if(0)
    %%
    plot(lutData);
    
end
end


function x=movmax_(v,n)

i=max(1,min(bsxfun(@plus,1:length(v),(0:n)'),numel(v)));
x=max(v(i));

end
