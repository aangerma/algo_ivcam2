%folder1 = 'D:\Data\Ivcam2\PZR\Captures\0312\002';
%sphCap = readSphericalSyncPZR(folder1);
%matchPZRs(sphCap, sphRegs, wCap);

%folder = 'D:\Data\Ivcam2\PZR\Captures\0312\';
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

verbose = true;

%{
for i=1:n
    f = [folder folders(i).name];
    mclog = matchPZRs(readSphericalSyncPZR(f), sphRegs, wCap, false, folders(i).name);
end
%}

for i=1:n
    f = [folder folders(i).name];
    mclog = matchPZRs(readSphericalSyncPZR(f), sphRegs, wCap);
    mclogs{i} = mclog;
end

shift = 223;

for i=1:n
    res(i) = new_pzr2ang(mclogs{i}, shift, verbose);
end

for i=1:n
    %delay(i) = computeDelay(mclogs{i});
    %[X0(:,i),X1(:,i),X2(:,i), errAngBest(:,i), tBest(:,i), errMaxAbsBest(:,i)] = tom_pzr2ang(mclogs{i});
    resP(i) = new_pzr2ang_polyfit(mclogs{i}, shift);
    close all;
end

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

figure; plot(1:n, [res.c]); title('Full fit');
figure; plot(1:n, [res.cLF]); title('Low pass fit');
figure; plot(1:n, [res.cHF]); title('High pass fit');
figure; plot(1:n, [res.meanErr]); title('Mean error: full fit');
figure; plot(1:n, [res.meanErrLF]); title('Mean error: low pass fit');
figure; plot(1:n, [res.meanErrHF]); title('Mean error: high pass fit');

%%

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
