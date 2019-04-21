function [res] = new_pzr2ang(mclog, shift, gConf, verbose)


if ~exist('verbose','var')
    verbose = false;
end

%% filters
fOrder = 150;
bLP = firpm(fOrder,[0 1.5 18 1e3/2]/(1e3/2),[1 1 0 0], [1 20]);
bHP = firpm(fOrder,[0 1.5 18 1e3/2]/(1e3/2),[0 0 1 1], [20 1]);
[be2,ae2] = ellip(2,0.1,13,1.0/(1000/2));

%h = fvtool(bLP, 1, be2,ae2);
%h = fvtool(bLP, 1, bHP,1);
postOrder = 36;
bLPpzr = firpm(postOrder,[0 2.5 18 1e3/2]/(1e3/2),[1 1 0 0], [1 1]);
%bLPpzr = firpm(150,[0 3 15 1e3/2]/(1e3/2),[0 0 1 1], [1 10]);
if (false)
    h = fvtool(bLPpzr, 1);
    h.Fs = 1e6;
    h.NumberofPoints = 2^20;
    h.FrequencyScale = 'log';
end


%%
n = length(mclog.actAngX);
RF = (fOrder/2+1):(n-fOrder/2); % filter range
R=1:n;                          % full range

%% compute filter low frequences
fLfActAngX = conv(mclog.actAngX,bLP,'valid');
fLfPZR1 = conv(mclog.PZR1,bLP,'valid');
fLfPZR3 = conv(mclog.PZR3,bLP,'valid');
if (verbose)
    figure; plot(R, mclog.actAngX, RF, fLfActAngX);
    figure; plot(RF,fLfPZR1,RF,fLfPZR3); title('Filter low pass of PZRs');
end

pAngX = polyfit(R, mclog.actAngX,4);
pPZR1 = polyfit(R, mclog.PZR1,4);
pPZR3 = polyfit(R, mclog.PZR3,4);

pLfActAngX = polyval(pAngX,R);
pLfPZR1 = polyval(pPZR1,R);
pLfPZR3 = polyval(pPZR3,R);

if (verbose)
    figure; plot(R, mclog.actAngX, R, pLfActAngX, RF, fLfActAngX);
    title('Filter and poly low pass vs actual angle X'); legend('actual', 'poly', 'filter');
    figure; plot(R, mclog.PZR1, R, pLfPZR1, RF, fLfPZR1);
    title('Filter and poly low pass vs original PZR1'); legend('PZR1', 'poly', 'filter');
    figure; plot(R, mclog.PZR3, R, pLfPZR3, RF, fLfPZR3);
    title('Filter and poly low pass vs original PZR3'); legend('PZR3', 'poly', 'filter');
end

%% high freq > 15k+

% diff with filter low freqs
fdHfPZR1 = mclog.PZR1(RF)-fLfPZR1;
fdHfPZR3 = mclog.PZR3(RF)-fLfPZR3;
fdHfActAngX = mclog.actAngX(RF)-fLfActAngX;

% filter high freqs
fHfActAngX = conv(mclog.actAngX,bHP,'valid');
fHfPZR1 = conv(mclog.PZR1,bHP,'valid');
fHfPZR3 = conv(mclog.PZR3,bHP,'valid');

% diff with filter high freqs
pdHfPZR1 = mclog.PZR1-pLfPZR1;
pdHfPZR3 = mclog.PZR3-pLfPZR3;
pdHfActAngX = mclog.actAngX-pLfActAngX;
lph2k = conv(pdHfActAngX,bLPpzr,'same');


nlpPZR1 = conv(mclog.PZR1, bLPpzr,'valid');
nlpPZR3 = conv(mclog.PZR3, bLPpzr,'valid');

% if (verbose)
%     figure; plot(1:n,fHfPZR1,1:n,fHfPZR3);
%     figure; plot(fHfActAngX);
%     figure; plot(dcActAngX+hfActAngX); hold on; plot(mclog.actAngX(RF));
% end

if (verbose)
    figure; plot(R, pdHfActAngX, RF, fdHfActAngX, RF, fHfActAngX);
    title('High frequences of angle X'); legend('poly diff', 'LP filter diff', 'HP filter');
    figure; plot(R, pdHfPZR1, RF, fdHfPZR1, RF, fHfPZR1);
    title('High frequences of PZR1'); legend('poly diff', 'LP filter diff', 'HP filter');
    figure; plot(R, pdHfPZR3, RF, fdHfPZR3, RF, fHfPZR3);
    title('High frequences of PZR3'); legend('poly diff', 'LP filter diff', 'HP filter');
end

%% analyze given coefficients

funC = @(pzr1, pzr3, c)(pzr1*c(1)+pzr3*c(2)+c(3));

%% gConf

if (~isempty(gConf))
    CL = gConf.CL;
    CH = gConf.CH;
    
    resFangX = funC(fLfPZR1, fLfPZR3, CL) + funC(fHfPZR1, fHfPZR3, CH) + gConf.offsetF;
    resFDangX = funC(fLfPZR1, fLfPZR3, CL) + funC(fdHfPZR1, fdHfPZR3, CH) + gConf.offsetFD;
    
    N = length(fLfPZR1);

    RA = 1+shift:N;
    RZ = 1:N-shift;
    res.errFilter = computeError(resFangX(RZ), mclog.actAngX(RA));
    res.errFilterD = computeError(resFDangX(RZ), mclog.actAngX(RA));
    
    res.resFangX = resFangX(RZ);
    res.resFDangX = resFDangX(RZ);
    res.actAngX = mclog.actAngX(RA);
    
    if (false)
        R = 1:length(RZ);
        figure; plot(R, resFangX(RZ), R, mclog.actAngX(RA)); title('LF-HF filter comparisson');
        figure; plot(R, resFDangX(RZ), R, mclog.actAngX(RA)); title('LF-diff filter comparisson');
    end

    %PZR_A = 40.8254460518298;
    %PZR_B = 28.6259521358624;
    %resPZR = conv(funC(mclog.PZR1, mclog.PZR3, [PZR_A/2 PZR_B/2 0]), bLPpzr,'valid');
    resPZR = conv(funC(mclog.PZR1, mclog.PZR3, CL), bLPpzr,'valid');
    N = length(resPZR);
    RA = 1+shift:N;
    RZ = 1:N-shift;
    res.errPZR = computeError(resPZR(RZ), mclog.actAngX(RA));
    if (false)
        R = 1:length(RZ);
        figure; plot(R, resPZR(RZ), R, mclog.actAngX(RA)); title('PZR with post-LP filter comparisson');
    end

    return;
end


%% find shift

maxShift = 300;

CF_LF = zeros(3,maxShift); % fit coeffs: filter low freq
CP_LF = zeros(3,maxShift); % fit coeffs: poly low freq

CF_HF  = zeros(3,maxShift); % fit coeffs: filter high freq
CFD_HF = zeros(3,maxShift); % fit coeffs: filter diff with low freq
CPD_HF = zeros(3,maxShift); % fit coeffs: poly diff with low freq

CFull = zeros(3,maxShift); % full fit coeffs

N = length(fLfPZR1);
for s=1:maxShift
    k = fOrder/2;
    RA = 1+s+k:N;
    RZ = 1:N-s-k;
    [CF_LF(:,s), meanErr_fLF(s), maxErr_fLF(s), rmsErr_fLF(s)] = lsFit(fLfPZR1(RZ),fLfPZR3(RZ),fLfActAngX(RA));
    [CF_HF(:,s), meanErr_fHF(s), maxErr_fLF(s), rmsErr_fLF(s)] = lsFit(fHfPZR1(RZ),fHfPZR3(RZ),fHfActAngX(RA));
    [CFD_HF(:,s), meanErr_fdHF(s), maxErr_fdLF(s), rmsErr_fdLF(s)] = lsFit(fdHfPZR1(RZ),fdHfPZR3(RZ),fdHfActAngX(RA));
    RA = 1+s:n;
    RZ = 1:n-s;
    [CP_LF(:,s), meanErr_pLF(s), maxErr_pLF(s), rmsErr_pLF(s)] = lsFit(pLfPZR1(RZ),pLfPZR3(RZ),pLfActAngX(RA));
    [CPD_HF(:,s), meanErr_pdHF(s), maxErr_pdHF(s), rmsErr_pdHF(s)] = lsFit(pdHfPZR1(RZ),pdHfPZR3(RZ),pdHfActAngX(RA));
    [CFull(:,s), meanErr_full(s), maxErr_full(s), rmsErr_full(s)] = lsFit(mclog.PZR1(RZ),mclog.PZR3(RZ),mclog.actAngX(RA));
    
    k = postOrder/2;
    RA = 1+s+k:length(nlpPZR1);
    RZ = 1:length(nlpPZR1)-s-k;
    [CC(:,s), meanErr_cc(s), maxErr_cc(s), rmsErr_cc(s)] = lsFit(nlpPZR1(RZ),nlpPZR3(RZ),mclog.actAngX(RA));
end

if ~exist('shift','var')
    minShift = 60;
    meanErr_pLF(1:minShift) = max(meanErr_pLF);
    [~,sBestLF] = min(meanErr_pLF);
    bestR = max(sBestLF-10,1):min(sBestLF+10,maxShift);
    [~,sBestHF] = min(meanErr_pdHF(bestR));
    sBest = sBestLF-10+sBestHF-1;
else
    sBest = shift;
end

%% compare


res.cfLF = CF_LF(:,sBest);
res.cfHF = CF_HF(:,sBest);
res.cfdHF = CFD_HF(:,sBest);
res.cpLF = CP_LF(:,sBest);
res.cpdHF = CPD_HF(:,sBest);

res.cFull = CFull(:,sBest);
res.cC = CC(:,sBest);

resFangX = funC(fLfPZR1, fLfPZR3, res.cfLF) + funC(fHfPZR1, fHfPZR3, res.cfHF);
resFDangX = funC(fLfPZR1, fLfPZR3, res.cfLF) + funC(fdHfPZR1, fdHfPZR3, res.cfdHF);

resPDangX = funC(pLfPZR1, pLfPZR3, res.cpLF) + funC(pdHfPZR1, pdHfPZR3, res.cpdHF);

resABangX = funC(mclog.PZR1(RF), mclog.PZR3(RF), res.cpLF);
resMCangX = filter(be2,ae2, resABangX);

resCCangX = funC(mclog.PZR1, mclog.PZR3, res.cC);

% filter
RA = 1+sBest:N;
RZ = 1:N-sBest;
res.errFilter = computeError(resFangX(RZ), mclog.actAngX(RA));
res.errFilterD = computeError(resFDangX(RZ), mclog.actAngX(RA));

R = 1:length(RZ);
if (verbose)
    figure; plot(R, resMCangX(RZ), R, mclog.actAngX(RA)); title('PZR and LF comparisson');
    figure; plot(R, resFangX(RZ), R, mclog.actAngX(RA)); title('LF-HF filter comparisson');
    figure; plot(R, resFDangX(RZ), R, mclog.actAngX(RA)); title('LF-diff filter comparisson');
    figure; plot(R, resCCangX(RZ), R, mclog.actAngX(RA)); title('post-LF filter comparisson');
end

% poly
RA = 1+sBest:n;
RZ = 1:n-sBest;
res.errPolyD = computeError(resPDangX(RZ), mclog.actAngX(RA));

R = 1:length(RZ);
if (verbose)
    figure; plot(R, resPDangX(RZ), R, mclog.actAngX(RA)); title('Poly comparisson');
end

return;

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


