function [res] = new_pzr2ang(mclog, shift)

%% filters
fOrder = 150;
bLP = firpm(fOrder,[0 1.5 18 1e3/2]/(1e3/2),[1 1 0 0], [1 20]);
bHP = firpm(fOrder,[0 1.5 18 1e3/2]/(1e3/2),[0 0 1 1], [20 1]);
[be2,ae2] = ellip(2,0.1,11.5,1.0/(1000/2));
%{
%h = fvtool(bLP, 1, be2,ae2);
h = fvtool(bLP, 1, bHP,1);
h.Fs = 1e6;
h.NumberofPoints = 2^20;
h.FrequencyScale = 'log';
%}

%%
n = length(mclog.actAngX);
R = (fOrder/2+1):(n-fOrder/2);

%% compute dc
dcActAngX = conv(mclog.actAngX,bLP,'valid');
dcPZR1 = conv(mclog.PZR1,bLP,'valid');
dcPZR3 = conv(mclog.PZR3,bLP,'valid');
figure; plot(1:n, mclog.actAngX, R, dcActAngX);
figure; plot(R,dcPZR1,R,dcPZR3);

pAngX = polyfit(1:n, mclog.actAngX,4);
dcActAngX = polyval(pAngX,1:n);
figure; plot(1:n, mclog.actAngX, 1:n, dcActAngX);

pPZR1 = polyfit(1:n, mclog.PZR1,4);
dcPZR1 = polyval(pPZR1,1:n);
figure; plot(1:n, mclog.PZR1, 1:n, dcPZR1);

pPZR3 = polyfit(1:n, mclog.PZR3,4);
dcPZR3 = polyval(pPZR3,1:n);
figure; plot(1:n, mclog.PZR3, 1:n, dcPZR3);


%{
[CLF, errMean, errRMS] = lsFit(dcPZR1,dcPZR3,dcActAngX);
figure; plot(R,dcPZR1*CLF(1)+dcPZR3*CLF(2)+CLF(3),R,dcActAngX);

figure; plot(filter(be2,ae2,mclog.PZR1*CLF(1) + mclog.PZR3*CLF(2)+CLF(3)));
hold on; plot(mclog.actAngX);
%}

%% MC results
%{
PZR_A = 40.8254460518298;
PZR_B = 28.6259521358624;
PZR_A/PZR_B

figure; plot((mclog.PZR1*PZR_A + mclog.PZR3*PZR_B)/2);
hold on; plot(mclog.actAngX+0.8);

figure; plot(filter(be2,ae2,(mclog.PZR1*PZR_A + mclog.PZR3*PZR_B)/2));
hold on; plot(mclog.actAngX+0.8);
%}
%% high freq > 15k+

%hfPZR1 = mclog.PZR1(R)-dcPZR1;
%hfPZR3 = mclog.PZR3(R)-dcPZR3;
%hfActAngX = mclog.actAngX(R)-dcActAngX;

%hfActAngX = conv(mclog.actAngX,bHP,'valid');
%hfPZR1 = conv(mclog.PZR1,bHP,'valid');
%hfPZR3 = conv(mclog.PZR3,bHP,'valid');

hfPZR1 = mclog.PZR1-dcPZR1;
hfPZR3 = mclog.PZR3-dcPZR3;
hfActAngX = mclog.actAngX-dcActAngX;

figure; plot(1:n,hfPZR1,1:n,hfPZR3);
figure; plot(hfActAngX);
figure; plot(dcActAngX+hfActAngX); hold on; plot(mclog.actAngX(R));


maxShift = 300;
CHF = zeros(3,maxShift);
CLF = zeros(3,maxShift);
CFull = zeros(3,maxShift);

N = length(hfPZR1);
for s=1:maxShift
    RA = 1+s:N;
    RZ = 1:N-s;
    [CHF(:,s), meanErrHF(s), maxErrHF(s), rmsErrHF(s)] = lsFit(hfPZR1(RZ),hfPZR3(RZ),hfActAngX(RA));
    [CLF(:,s), meanErrLF(s), maxErrLF(s), rmsErrLF(s)] = lsFit(dcPZR1(RZ),dcPZR3(RZ),dcActAngX(RA));
    fullRA = 1+s:n;
    fullRZ = 1:n-s;
    [CFull(:,s), meanErr(s), maxErr(s), rmsErr(s)] = lsFit(mclog.PZR1(fullRZ),mclog.PZR3(fullRZ),mclog.actAngX(fullRA));
end

minShift = 60;
meanErrLF(1:minShift) = max(meanErrLF);

if ~exist('shift','var')
    [~,sBestLF] = min(meanErrLF);
    bestR = max(sBestLF-10,1):min(sBestLF+10,maxShift);
    [~,sBestHF] = min(meanErrHF(bestR));
    sBest = sBestLF-10+sBestHF-1;
else
    sBest = shift;
end

RA = 1+sBest:N;
RZ = 1:N-sBest;

cLF = CLF(:,sBest);
cHF = CHF(:,sBest);
SA_LF = mclog.PZR1*cLF(1) + mclog.PZR3*cLF(2)+cLF(3);
filtSA = filter(be2,ae2,SA_LF);
%figure; plot(filtSA(RZ));
figure; plot(SA_LF(RZ));
hold on; plot(mclog.actAngX(RA));

dcFit = dcPZR1*cLF(1) + dcPZR3*cLF(2)+cLF(3);
hfFit = hfPZR1*cHF(1) + hfPZR3*cHF(2)+cHF(3);
errorFit = dcFit(RZ)+hfFit(RZ)-mclog.actAngX(RA);
figure; plot(dcFit(RZ)+hfFit(RZ));
hold on; plot(mclog.actAngX(RA));

%figure;
%subplot(1,2,1); plot(hfPZR1(RZ)*cHF(1) + hfPZR3(RZ)*cHF(2)+cHF(3));
%subplot(1,2,2); plot(hfActAngX(RA));

%%

res.errorFit = errorFit;
res.meanError = mean(errorFit);
res.maxError = max(errorFit);
res.stdError = std(errorFit);

res.shift = sBest;
res.cLF = CLF(:,sBest);
res.cHF = CHF(:,sBest);
res.c = CFull(:,sBest);

res.meanErrLF = meanErrLF(sBest);
res.meanErrHF = meanErrHF(sBest);
res.meanErr = meanErr(sBest);

res.dcActAngX = dcActAngX;
res.dcPZR1 = dcPZR1;
res.dcPZR3 = dcPZR3;

res.hfActAngX = hfActAngX;
res.hfPZR1 = hfPZR1;
res.hfPZR3 = hfPZR3;

return;

figure; plot(filter(be2,ae2,mclog.PZR1*C(1) + mclog.PZR3*C(2)+C(3)));
hold on; plot(mclog.actAngX);

figure; plot(dcActAngX);
hold on; plot((dcPZR1*PZR_A + dcPZR3*PZR_B)/2-1);
figure; plot((dcPZR1*PZR_A + dcPZR3*PZR_B)/2-1.03-dcActAngX);

figure; plot(filter(be2,ae2,(mclog.PZR1*PZR_A + mclog.PZR3*PZR_B)/2));
hold on; plot(mclog.actAngX+0.8);

figure; plot(mclog.actAngX(R)-dcActAngX);

figure; plot(dcActAngX);
hold on; plot(mclog.actAngX(R));

end


