clear variables
clc

%%

load('F9240063.mat')

% inputFolder = 'D:\temp\delayPerTemp\';
inputFolder = 'X:\Users\syaeli\Work\Code\algo_ivcam2\scripts\delaysCalib\Recordings\';
nEpochs = 10;
for k = 1:nEpochs
    load([inputFolder, sprintf('epoch_%d_pre.mat',k)]);
    preImages(:,:,k) = x.i;
    load([inputFolder, sprintf('epoch_%d_post.mat',k)]);
    postImages(:,:,k) = x.i;
end

%% IR

clear F
figure
for k = 1:nEpochs
    if (k==1)
        h = imagesc(preImages(:,:,k));
        set(gca,'xdir','reverse')
        set(gca,'ydir','normal')
        colormap gray
        set(gca,'clim',[-20,20])
    else
        set(h, 'CData', preImages(:,:,k))
    end
    title(sprintf('IR image (T = %.2f[deg])', temps(k)))
    F(k) = getframe(gcf);
    pause(1)
end
writerObj = VideoWriter('AVIs\IR.avi');
writerObj.FrameRate = 2;
open(writerObj)
for k = 1:nEpochs
    writeVideo(writerObj, F(k));
end
close(writerObj)

%% VDER

clear F
figure
for k = 1:nEpochs
    if (k==1)
        h = imagesc(diff(single(preImages(:,:,k)),[],1));
        set(gca,'xdir','reverse')
        set(gca,'ydir','normal')
        set(gca,'clim',[-20,20])
    else
        set(h, 'CData', diff(single(preImages(:,:,k)),[],1))
    end
    title(sprintf('IR vertical derivative (T = %.2f[deg])', temps(k)))
    F(k) = getframe(gcf);
    pause(1)
end
writerObj = VideoWriter('AVIs\vder.avi');
writerObj.FrameRate = 2;
open(writerObj)
for k = 1:nEpochs
    writeVideo(writerObj, F(k));
end
close(writerObj)

%%

figure
for k = 1:nEpochs
    if (k==1)
        h = imagesc(postImages(:,:,k));
        set(gca,'xdir','reverse')
        set(gca,'ydir','normal')
        colormap grayfig
    else
        set(h, 'CData', postImages(:,:,k))
    end
    title(sprintf('T = %.2f[deg]', temps(k)))
    pause(1)
end
