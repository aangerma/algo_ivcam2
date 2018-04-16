%% init delay and gradients
iFrame = 61;
ir = double(frames{iFrame, 1}.i); ir(isnan(ir)) = 0;
a1 = double(frames{iFrame, 2}.i); a1(isnan(a1)) = 0;
a2 = double(frames{iFrame, 3}.i); a2(isnan(a2)) = 0;

%% regular gradient
dir = diff(ir);
da1 = diff(a1);
da2 = diff(a2);

%% sigmoid kernel gradient
kerLen = 3;
kerEdge = 1./(1+exp((-kerLen:kerLen)*1.5))-0.5;
%figure; plot(kerEdge)

dir = conv2(ir, kerEdge', 'valid');
da1 = conv2(a1, kerEdge', 'valid');
da2 = conv2(a2, kerEdge', 'valid');


%% positive and negative gradients
CRY = 100:380; % cropped range
CRX = 50:500; % cropped range

dir_p = dir(CRY,CRX);
dir_p(dir_p < 0) = 0;
dir_n = dir(CRY,CRX);
dir_n(dir_p > 0) = 0;

da1_p = da1(CRY,CRX);
da1_p(da1_p < 0) = 0;
da1_n = da1(CRY,CRX);
da1_n(da1_n > 0) = 0;

da2_p = da2(CRY,CRX);
da2_p(da2_p < 0) = 0;
da2_n = da2(CRY,CRX);
da2_n(da2_n > 0) = 0;

%% correlation

ns = 15; % search range

corr1 = conv2(dir_p, flipud(fliplr(da1_p(ns+1:end-ns,:))), 'valid');
corr2 = conv2(dir_n, flipud(fliplr(da2_n(ns+1:end-ns,:))), 'valid');
figure; plot([corr1 flipud(corr2)]); title (sprintf('delay: %g', iFrame));
figure; plot([corr1 corr2]); title (sprintf('delay: %g (same dir)', iFrame));

[~,iMax1] = max(corr1);
[~,iMax2] = max(corr2);

corr1z = conv2(dir_p, flipud(fliplr(da1_n(ns+1:end-ns,:))), 'valid');
corr2z = conv2(dir_n, flipud(fliplr(da2_p(ns+1:end-ns,:))), 'valid');
figure; plot([corr1z flipud(corr2z)]); title (sprintf('delay: %g', iFrame));

%% check all

resDelays = zeros(1,size(frames,1));
for iFrame = 1:size(frames,1)
    ir = double(frames{iFrame, 1}.i); ir(isnan(ir)) = 0;
    a1 = double(frames{iFrame, 2}.i); a1(isnan(a1)) = 0;
    a2 = double(frames{iFrame, 3}.i); a2(isnan(a2)) = 0;
    
    resDelays(iFrame) = findCoarseDelay(ir, a1,a2);
end

%%

altFrames = zeros([size(frames,1) fliplr(size(frames{1, 1}.i))]);
dirFrames = zeros([size(frames,1) fliplr(size(frames{1, 1}.i).*[1 2])]);
ir2Frames = zeros([size(frames,1) fliplr(size(frames{1, 1}.i).*[1 2])]);
for iFrame = 1:size(frames,1)
    altFrames(iFrame,:,:) = frames{iFrame, 4}.i';
    dirFrames(iFrame,:,:) = [frames{iFrame, 2}.i frames{iFrame, 3}.i]';
    ir2Frames(iFrame,:,:) = [irFrames{iFrame, 2}.i irFrames{iFrame, 3}.i]';
end

figure;
for iFrame = 1:size(frames,1)
    imagesc([frames{iFrame, 2}.i frames{iFrame, 3}.i], [20  180]);
    title(iFrame); drawnow; pause(0.3);
end

figure;
for iFrame = 1:size(frames,1)
    imagesc(frames{iFrame, 4}.i);
    title(iFrame); drawnow; pause(0.2);
end


%% single column
C = 124;
c_dir = dir(:,C);
c_a1 = da1(:,C);
c_a2 = da2(:,C);

c_dir_p = c_dir;
c_dir_p(c_dir < 0) = 0;
c_dir_n = c_dir;
c_dir_n(c_dir > 0) = 0;

c_a1_p = c_a1;
c_a1_p(c_a1 < 0) = 0;
c_a1_n = c_a1;
c_a1_n(c_a1 > 0) = 0;

c_a2_p = c_a2;
c_a2_p(c_a2 < 0) = 0;
c_a2_n = c_a2;
c_a2_n(c_a2 > 0) = 0;

figure; plot([c_dir c_a1 c_a2])
figure; plot([c_dir_p c_a1_p])
figure; plot([c_dir_n c_a1_n])