figure; plot(1:n, [res.c]); title('Full fit');
figure; plot(1:n, [res.cLF]); title('Low pass fit');
figure; plot(1:n, [res.cHF]); title('High pass fit');
figure; plot(1:n, [res.meanErr]); title('Mean error: full fit');
figure; plot(1:n, [res.meanErrLF]); title('Mean error: low pass fit');
figure; plot(1:n, [res.meanErrHF]); title('Mean error: high pass fit');


%% all actual angle X

figure; hold on;
for i=1:n
    plot(mclogs{i}.actAngX);
end

%% find approao times

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
    ah = mclogs{i}.actAngX;
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
