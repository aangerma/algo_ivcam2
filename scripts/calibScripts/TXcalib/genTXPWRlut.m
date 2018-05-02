function lutOUT=genTXPWRlut(v_gainTable,modulationRef,slopeEfficiency,ibias,yfov)
%{
generate txPWRlut based on gainTable data

%inputs:
gainTable            %#[0-255] from degree
modulationRef        %mA from # Iout = modulationRef/63*150+150
slopeEfficiency      %mW from mA
ibias                %mA
yfov                 %degree
    
%example:    
    
load v_gainTable
modulationRef=60;
slopeEfficiency=0.25;
ibias=2;
yfov=50    
lutOUT=genTXPWRlut(v_gainTable,modulationRef,slopeEfficiency,ibias,yfov)
    
%}

PA_CLK=125e6;%shz
MIRROR_FREQ=20e3;%Hz

N_LUT_BINS = 65; %fixed, numer of LUT bins

%algo input, might change over time. this is how we model the delay behavior as function of tx power
delayModel = @(P) single(-0.000312*P.^2+0.087202*P-5.743036); 


gainT=v_gainTable(:,1);
gainV=v_gainTable(:,2);



%ldd input current
iref = modulationRef/63*150+150;
imod = single(gainV)/255*iref;
iout = imod+ibias;

%optical out power
pout = iout*slopeEfficiency;

%delay as function of power
tauOut = delayModel(pout);

%input is per angle - distribute angles from [-yfov/2,yfov/2]
yangIn = -cos(2*pi*MIRROR_FREQ*gainT)*yfov/2;
%convert to pixels (approx.). min pxel=0, max pixel=N_LUT_BINS-1
ypixIn = (tand(yangIn)/tand(yfov/2)+1)*(N_LUT_BINS-1)/2+1;
%linear interpolation
lastIncreasingInd=find(diff(ypixIn)<0,1);

lutOUT = interp1(ypixIn(1:lastIncreasingInd),tauOut(1:lastIncreasingInd),1:N_LUT_BINS);

end
