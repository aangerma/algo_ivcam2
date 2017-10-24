
load('X:\Users\tmund\pipeOut100.mat');    
%% Confidance network - gather the following data:
% psnr
% max_val
% duty cycle
% IR
% depth_pipe
% depth_gt 
n_pixels = numel(results(1).gt.zImg); % number of pixels in image
dataMat = zeros(length(results)*n_pixels,6);
for i=1:length(results)
    %%
    depth_gt = single(results(i).gt.zImg);
    depth_pipe = single(results(i).zImgRAW/8);
    IR = single(results(i).iImgRAW);
    dutyCycle = single(results(i).dutyCycle);
    psnr = single(results(i).psnr);
    maxVal = single(results(i).max_val);
    
    % Valid pixels
    validPix = IR>0;
    % Change to 6bit:
    IR = floor(IR/2^6);
    dutyCycle = dutyCycle*4;
    
    
    dataMat = [psnr(:),maxVal(:),dutyCycle(:),IR(:),depth_pipe(:),depth_gt(:)];
    
    
    % Filter pixels with ir == 0 (invalid)
    dataMat = dataMat(validPix,:);
    if ~isempty(dataMat)
        % shuffle the data
        dataMat = dataMat(randperm( size(dataMat,1) ) ,:);
        % save current frame in a binary format
        mainDir = 'X:\Data\IvCam2\NN\Confidence\sintelBinFrames';
        fn = fullfile(mainDir,strcat('frame_',num2str(ind(i)),'.bin'));
        fid = fopen(fn,'wb');
        fwrite(fid,single(vec(dataMat')),'single');
        fclose(fid);
        fprintf('Done\n');
    
    end
end




