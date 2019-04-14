%folder1 = 'D:\Data\Ivcam2\PZR\Captures\0312\002';
%sphCap = readSphericalSyncPZR(folder1);
%matchPZRs(sphCap, sphRegs, wCap);

%folder = 'D:\Data\Ivcam2\PZR\Captures\0312\';

%% read filenames
folder = 'D:\Data\Ivcam2\PZR\Captures\0404\';
load([folder 'world_PZR.mat']);
if ~exist('sphRegs','var')
    sphRegs = regs;
end

wCap.regs.FRMW.laserangleH = single(0);
wCap.regs.FRMW.laserangleV = single(0);

folders0 = dir([folder '0*.*']);
folders1 = dir([folder '1*.*']);

n0 = length(folders0);
n1 = length(folders1);
folders = folders0;
folders(n0+(1:n1))=folders1;

n = length(folders);
X0 = zeros(4,n);
X1 = zeros(3,n);
X2 = zeros(3,n);
mclogs = cell(1,n);

%%

verbose = true;

strRead = ['reading and matching PZRs %u of ' sprintf('%u', n)];
fprintf_r('reset');

for i=1:n
    f = [folder folders(i).name];
    mclog = matchPZRs(readSphericalSyncPZR(f), sphRegs, wCap, false, folders(i).name);
    mclogs{i} = mclog;
    fprintf_r(strRead, i);
end


%%

shift = 223;


%%

for i=1:n
    res(i) = new_pzr2ang_all(mclogs{i}, shift, [], verbose);
end

%%


%% analyze

%figure; plot(1:n, [res.c]); title('Full fit');
figure; plot(1:n, [res.cfLF]); title('Low pass fit');
figure; plot(1:n, [res.cfHF]); title('High pass fit');
figure; plot(1:n, [res.cfdHF]); title('High pass diff fit');
figure; plot(1:n, [res.cpLF]); title('Low pass poly fit');
figure; plot(1:n, [res.cpdHF]); title('High pass diff poly fit');

errFilter = [res.errFilter];
errFilterD = [res.errFilterD];
errPolyD = [res.errPolyD];

figure; plot(1:n, [errFilter.offset]); title('Offset: filters');
figure; plot(1:n, [errFilterD.offset]); title('Offset: filter diff');
figure; plot(1:n, [errPolyD.offset]); title('Offset: poly');

figure; plot(1:n, [errPolyD.std]); title('Std error: poly');
figure; plot(1:n, [errFilter.std]); title('Std error: filter');
figure; plot(1:n, [errFilterD.std]); title('Std error: filter diff');
figure; plot(1:n, [res.meanErrHF]); title('Mean error: high pass fit');

%% global coefficients

gConf.CL = mean([res.cpLF],2);
gConf.CH = mean([res.cpdHF],2);
gConf.offsetFD = mean([errFilterD.offset]);
gConf.offsetF = mean([errFilter.offset]);

hfAtten = mean(gConf.CL(1:2) ./ gConf.CH(1:2));
hfAttenDb = mag2db(hfAtten);

% !!!!! checkboad linear interpolation error is high
i = 11;
figure; plot(mclogs{i}.angX-mclogs{i}.actAngX+D(i));
title('Difference between dsm angles and actual angles');

for i=1:n
    resG(i) = new_pzr2ang_all(mclogs{i}, shift, gConf, verbose);
end

R = 1:length(mclog.angX);
for i=1:n
    resA(i).px = polyfit(R, mclogs{i}.angX, 1)';
    resA(i).pax = polyfit(R, mclogs{i}.actAngX, 1)';
    D(i) = resA(i).pax(2)-resA(i).px(2);
end

N = length(mclogs{1}.angX);
for i=1:n
    RA = 1+shift:N;
    RZ = 1:N-shift;
    resErr(i) = computeError(mclogs{i}.angX(RZ), mclogs{i}.actAngX(RA)+mean(D));
end

gErrFilter = [resG.errFilter];
gErrFilterD = [resG.errFilterD];

figure; plot(1:n, [gErrFilter.offset]); title('Offset: filters');
figure; plot(1:n, [gErrFilterD.offset]); title('Offset: filter diff');

figure; plot(1:n, [gErrFilter.std]); title('STD: global coeffs with filters');
figure; plot(1:n, [gErrFilterD.std]); title('STD: global coeffs with filters diff');
figure; plot(1:n, [resErr.std]); title('STD: dsm angle vs actual angles');

figure; plot(1:n, [gErrFilter.max]); title('Max error: filters');
figure; plot(1:n, [gErrFilterD.max]); title('Max error: filter diff');

%i = 2;
%figure; plot(resG(i).resFangX); hold on; plot(resG(i).actAngX);

%%

for i=1:n
    delay(i) = computeDelay(mclogs{i});
end

for i=1:n
    if (verbose)
        figure; plot(mclog.actAngX, mclog.actAngY, '.-');
        hold on; plot(mclog.angX,mclog.angY, '.-');
        %plot((mclog.PZR1*PZR_A+mclog.PZR3*PZR_B)/2, mclog.actAngY, '.-');
        title(sprintf('Mirror angle start: %.2f', mclog.angX(1)));
        
        figure; plot(mclog.actAngX, '.-');
        hold on; plot(mclog.angX, '.-');
        %hold on; plot((mclog.PZR1*PZR_A+mclog.PZR3*PZR_B)/2, '.-b');
        %hold on; plot(mclog.PZR1*X1(1,i)+mclog.PZR3*X1(2,i), '.-');
        %legend('Actual','DSM input', 'PZR1+PZR3');
    end

    close all;
end


C = mean([resP.cLF],2);

N = length(mclog.actAngX);
for i=1:n
    mclog = mclogs{i};
    RA = 1+shift:N;
    RZ = 1:N-shift;
    %figure; plot(mclog.actAngX(RA));
    pzrs = mclog.PZR1(RZ)*C(1)+mclog.PZR3(RZ)*C(2)+C(3);
    %hold on; plot(pzrs);
    figure; plot(mclog.actAngX(RA)-pzrs);
end

%% all actual angle X

figure; hold on;
for i=1:n
    plot(mclogs{i}.actAngX);
end

%% find approx times

tStart = zeros(1,n);
for i=1:n
    ax = mclogs{i}.actAngX;
    p = polyfit(1:length(ax),ax, 1);
    xStart = polyval(p,1);
    tStart(i) = xStart/p(1);
end 

figure; hold on;
for i=1:n
    ax = res(i).hfActAngX;
    plot((1:length(ax))+tStart(i), ax);
end

figure; hold on;
for i=1:n
    ax = mclogs{i}.actAngX;
    plot((1:length(ax))+tStart(i), ax);
end

figure; hold on;
for i=1:n
    ax = res(i).dcPZR1 - res(i).dcPZR3;
    plot((1:length(ax))+tStart(i), ax);
end


%%


R = 1:length(res(1).dcActAngX);
figure;
for i=1:n
    subplot(1,3,1); plot(R,res(i).hfPZR1,R,res(i).hfPZR3);ylim([-0.16 0.16]);
    title('High freq (>18K) of PZR1 and PZR3');
    subplot(1,3,2); plot(R,res(i).hfActAngX);
    title('High freq (>18K) of actual angle X');
    subplot(1,3,3); plot(res(i).dcPZR1-res(i).dcPZR3);
    title('Low freq diff (<18K) between PZR1 and PZR3 is ~2.5kHz');
    pause;
end

for i=1:n xStart(i)=mclogs{i}.angX(1); end
figure; plot(xStart, delay, '+');
