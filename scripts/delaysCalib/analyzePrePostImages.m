clear variables
clc

%%

res = 'XGA';

if strcmp(res,'VGA')
    load('F9240063_VGA.mat')
    inputFolder = 'D:\temp\delayPerTempVGA\';
    nEpochs = 9;
elseif strcmp(res,'XGA')
    load('F9240063_XGA.mat')
    inputFolder = 'D:\temp\delayPerTempXGA\';
    nEpochs = 8;
end

for k = 1:nEpochs
    load([inputFolder, sprintf('epoch_%d_pre.mat',k)]);
    preImages(:,:,k) = x.i;
    load([inputFolder, sprintf('epoch_%d_post.mat',k)]);
    postImages(:,:,k) = x.i;
end

%% AVIs

CreateVideoFromImages(preImages,  @(x) x,                    [],       'gray', 'IR image',               ['AVIs', res, '\IRpre.avi'],    10, temps)
CreateVideoFromImages(postImages, @(x) x,                    [],       'gray', 'IR image',               ['AVIs', res, '\IRpost.avi'],   10, temps)
CreateVideoFromImages(preImages,  @(x) diff(single(x),[],1), [-20,20], 'jet',  'IR vertical derivative', ['AVIs', res, '\VDERpre.avi'],  10, temps)
CreateVideoFromImages(postImages, @(x) diff(single(x),[],1), [-20,20], 'jet',  'IR vertical derivative', ['AVIs', res, '\VDERpost.avi'], 10, temps)
CreateVideoFromImages(preImages,  @(x) GetHTrans(x),         [2,5], 'jet',  'IR vertical edges',      ['AVIs', res, '\EDGEpre.avi'],  10, temps)
CreateVideoFromImages(postImages, @(x) GetHTrans(x),         [2,5], 'jet',  'IR vertical edges',      ['AVIs', res, '\EDGEpost.avi'], 10, temps)
