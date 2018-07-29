function lutOUT=genTXPWRlut(v_gainTable,modulationRef,ibias,yfov,yres,marginT,marginB)
%{
generate txPWRlut based on gainTable data

%inputs:
gainTable            %#[0-255] from degree
modulationRef        %mA from # Iout = modulationRef/63*150+150
ibias                %mA
yfov                 %degree
    
%example:    
    
load v_gainTable
modulationRef=60;
ibias=2;
yfov=50    
lutOUT=genTXPWRlut(v_gainTable,modulationRef,ibias,yfov)
    
%}


MIRROR_FREQ=20e3;%Hz

N_LUT_BINS = 65; %fixed, numer of LUT bins

%algo input, might change over time. this is how we model the delay behavior as function of tx power
delayModel = @(i) single((0.017754*i - 5.375485)); 


gainT=v_gainTable(:,1);
gainV=v_gainTable(:,2);



%ldd input current
iref = modulationRef/63*150+150;
imod = single(gainV)/255*iref;
iout = imod+ibias;



%delay as function of power
tauOut = delayModel(iout);

%input is per angle - distribute angles from [-yfov/2,yfov/2]
yangIn = -cos(2*pi*MIRROR_FREQ*gainT)*yfov/2;
%convert to pixels (approx.). min pxel=0, max pixel=N_LUT_BINS-1
ypixIn = single((tand(yangIn)/tand(yfov/2)+1)*((marginT+marginB)/yres+1)*(N_LUT_BINS-1)/2+1)-1+((marginT)/yres)*(N_LUT_BINS-1);
%linear interpolation
lastIncreasingInd=find(diff(ypixIn)<0,1);

lutOUT = interp1(ypixIn(1:lastIncreasingInd)+1,tauOut(1:lastIncreasingInd),0:N_LUT_BINS-1);

end
