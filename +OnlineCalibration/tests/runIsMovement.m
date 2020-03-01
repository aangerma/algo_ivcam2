% clear all;
% sceneDir = 'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Snapshots\LongRange 768X1024 (1920X1080)\3-6';
close all;
% clear all;
sceneDir = 'X:\IVCAM2_calibration _testing\20.2.20\F9440950\Videos\LongRange 480X640 (1920X1080)\2';%'X:\IVCAM2_calibration _testing\20.2.20\F9340491\Videos\LongRange 480X640 (1920X1080)\1';

yuy2files = dir(fullfile(sceneDir,'YUY2_YUY2_*'));
splittedStr = strsplit(yuy2files(1).name,'_');
splittedStr = strsplit(splittedStr{3},'x');
for i = 1:numel(yuy2files)
    [frames.yuy2(:,:,i),~] = du.formats.readBinRGBImage(fullfile(yuy2files(i).folder,yuy2files(i).name),[str2double(splittedStr{1}),str2double(splittedStr{2})],5);
end
%%
isMoveParams.edgeThresh4logicIm = 0.1;
isMoveParams.seSize = 3;
isMoveParams.moveThreshPixVal = 20;
params.moveGaussSigma = 1;
isMoveParams.moveThreshPixNum =  3e-05*size(frames.yuy2(:,:,1),1)*size(frames.yuy2(:,:,1),2);%35e-05*size(frames.yuy2(:,:,1),1)*size(frames.yuy2(:,:,1),2);
% isMoveParams.moveThreshPixNum =  3e-05*size(frame(2).color,1)*size(frame(1).color,2);


% for k = 2:numel(frame)
for k = 2:size(frames.yuy2,3)
    im1 = frames.yuy2(:,:,k-1);
    im2 = frames.yuy2(:,:,k);
%     im1 = frame(k-1).color;
%     im2 = frame(k).color;
    isMovement = OnlineCalibration.aux.isMovementInImages(im1,im2,isMoveParams);
    if isMovement
        disp('Movement detected!');
        figure; subplot(211);imagesc(im1);impixelinfo;
        subplot(212);imagesc(im2);impixelinfo; linkaxes;
        figure; imagesc(abs(im1-im2)); title('Absolute Diff');impixelinfo; colorbar;
    end
end
