function [sinx,cosx,siny,cosy,sinw,cosw,sing]=getTrigo(sz,regs)

%% hard-coded LUTs
N_LUT_BIN = 2^7;
MAX_TAN_VAL = 1;
tratn_x = single(linspace(0,MAX_TAN_VAL,N_LUT_BIN));

snatn_lutdata = tratn_x./sqrt(tratn_x.*tratn_x+1);
csatn_lutdata =       1./sqrt(tratn_x.*tratn_x+1);

snatn_INTRP = @(x) single(sign((x))).*triFuncIntrp(abs(x),snatn_lutdata);
csatn_INTRP = @(x)                    triFuncIntrp(abs(x),csatn_lutdata);

FACT = (N_LUT_BIN-1)/MAX_TAN_VAL; %SHOULD BE PART OF FIRMWARE
%%
[yi,xi]=ndgrid(0:sz(1)-1,0:sz(2)-1);
tanx = (regs.DEST.p2axa *xi+ regs.DEST.p2axb);
tany = (regs.DEST.p2aya *yi+ regs.DEST.p2ayb);
sinx = snatn_INTRP(tanx*FACT); %INTENAL NON ASIC
cosx = csatn_INTRP(tanx*FACT);
siny = snatn_INTRP(tany*FACT); %INTENAL NON ASIC
cosy = csatn_INTRP(tany*FACT); 



if(regs.MTLB.fastApprox(1))
    dnm = 1./sqrt(1+tanx.^2);
else
    dnm=Utils.fp32('invsqrt',1+tanx.*tanx);
end
tanw = tany.*dnm;

sinw = snatn_INTRP(tanw*FACT); %INTERNAL NON ASIC
cosw = csatn_INTRP(tanw*FACT);

if(regs.DEST.hbaseline)
	tanxFACT = tanx*FACT;
    sing = snatn_INTRP(tanxFACT.*cosy);
else
    sing = snatn_INTRP(tanw*FACT);
end




%  
end



function val = triFuncIntrp(ii,lut)
lut=lut(:);
ii= max(0,min(ii,length(lut)-1));%clipping
sz = size(ii);
ii = ii(:);
i0 = max(floor(ii),0); % the index round down
i1 = min(i0+1,length(lut)-1); % the index rounded up
y0 = lut(i0+1); % LUT value of index i0
y1 = lut(i1+1); % LUT value of index i1
val=(y1-y0).*(ii-i0)+y0; %weighted mean of the input (linear interp)
val = reshape(val,sz);
end



     
            