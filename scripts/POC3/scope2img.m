function [im,ivs] = scope2img(v,dt,params)

%%
if(~exist('params','var'))
    params.irPreFilt = [3 166e6+[-30 30]*1e6];
    params.irPostFilt = [3 0 64e6 ];
    params.pzr2los = [  .5       0          .5       1/8 1 -1/8];
    params.angxFilt = [3 0 15e3 0];
    params.angyFilt = [3 0 60e3 ];
    params.locPreFreq = 120e6;
    params.locPostFreq = 10e6;
    params.outFreq = 125e6;
    params.locIRdelay = 3069;
    params.outBin = 1024;
    params.anxgSO = [10 0];
    params.anygSO = [10 0];
end
%%
tia = v(:,1);
pzr1=v(:,2);
pzr2=v(:,4);
pzr3=v(:,3);
n = size(v,1);
clear v;
%%
irdata=tia;
irdata=runFilter(irdata,dt,params.irPreFilt);
irdata = abs(irdata);
irdata=runFilter(irdata,dt,params.irPostFilt);

sa = params.pzr2los(1:3)/sum(abs(params.pzr2los(1:3)))*[pzr1 pzr2 pzr3]';
fa = params.pzr2los(4:6)/sum(abs(params.pzr2los(4:6)))*[pzr1 pzr2 pzr3]';%= pzr2+0.25*(pzr1-pzr3)/2;
tend = dt*(n-1);
%change loc freq
dtL = 1/params.locPreFreq;
sa = interp1(0:dt:tend,sa,0:dtL:tend);
fa = interp1(0:dt:tend,fa,0:dtL:tend);

%SA filter
sa = runFilter(sa,dtL,params.angxFilt);
%FA filter
fa = runFilter(fa,dtL,params.angyFilt);

dtP = 1/params.locPostFreq;
sa = interp1(0:dtL:tend,sa,0:dtP:tend);
fa = interp1(0:dtL:tend,fa,0:dtP:tend);


% cut data
[bT,eT]=scaneBegEnd(sa,dtP);

dtO = 1/params.outFreq;
ivs.slow = interp1(0:dt:tend,irdata,bT:dtO:eT);
ivs.xy = interp1((0:(length(sa)-1))*dtP,[sa;fa]',bT:dtO:eT)';
% params.angxSO=[minmax(ivs.xy(1,:)); 1 1]'\[-1;1];
% params.angySO=[minmax(ivs.xy(2,:)); 1 1]'\[-1;1];

ivs.slow = uint16(ivs.slow*params.slowSO(1)+params.slowSO(2));

to12b = @(x) int16(min(1,max(-1,x))*(2^11-1));
ivs.xy = [to12b(ivs.xy(1,:)*params.angxSO(1)+params.angxSO(2));to12b(ivs.xy(2,:)*params.angySO(1)+params.angySO(2))];


im=raw2img(ivs,params.locIRdelay,params.outBin);
end


function [b,e]=scaneBegEnd(sa,dtL)
c = crossing([],sa,mean(sa));
c([0;diff(c)]<length(sa)/10)=[];
isRise = sa(floor(c))<mean(sa);
if(isRise(end))
    c(end+1)=length(sa);
 end
if(isRise(1))
    c=[1;c];
end
c=round(c);
    
b=(minind(sa(c(1):c(2)))+c(1))*dtL;
e=(maxind(sa(c(2):c(3)))+c(2))*dtL;
end


function vout=runFilter(vin,dt,p)
fs2=0.5/dt;
vout=vin;
for i=1:size(p,1)
    f = p(i,2:3);
    o=p(i,1);
    if(f(1)==0 && f(2)==0)
        continue;
    elseif(f(1)==0)%lowpass
        [b,a]=butter(o,f(2)/fs2,'low');
    elseif(f(2)==0)%highpass
        [b,a]=butter(o,f(1)/fs2,'high');
    elseif(f(1)>f(2))%band-stop
        [b,a]=butter(o,fliplr(f)/fs2,'stop');
    else%band pass
        [b,a]=butter(o,f/fs2);
    end
    vout=filtfilt(b,a,vout);
end

end

function img=raw2img(ivs,s,sz)

xy = (double(ivs.xy)/(2^11-1)+1)/2; %[0 1]
xy = round(xy*(sz-1)+1);
v = circshift(double(ivs.slow),s);


g = all(xy>0 & xy<=sz );

xy=xy(:,g);
v=v(g);

ind=sub2ind([1 1]*sz,xy(2,:),xy(1,:));

img=accumarray(ind',v,[sz*sz 1],@mean,nan);
img=reshape(img,[sz sz]);
end
