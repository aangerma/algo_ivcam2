preset = 'long';
switch preset
    case 'long'
        baseFolder = 'X:\Data\APD\longXga';
        myTitle = 'Long Range - XGA';
        resultsFigNum = 151285; 
    case 'short'
        baseFolder = 'X:\Data\APD\shortXga';
        myTitle = 'Short Range - XGA';
        resultsFigNum = 120784; 
    otherwise
        error('No Such Preset')
end

dirData = dir(baseFolder);

params.isRoiRect = 0;
params.roiCropRect = 0;
params.roi = 0.1;
for idir = 3:numel(dirData)
    load([baseFolder '\' dirData(idir).name '\data.mat']);
    
    [mask] = Validation.aux.getRoiMask(size(frames(1).z), params);
    figure(resultsFigNum-10); imagesc(imfuse(mask,frames(1).z));
    
    deltaDepth = nan(numel(apdVal),1);
    depthVal = nan(numel(apdVal),1);
    for k=1:numel(apdVal)
        if k > 1
            frameDiff = double(frames(k).z)./2-double(frames(k-1).z)./2;
            frameDiff = frameDiff(mask);
            deltaDepth(k) = mean(frameDiff(:));
        end
        currentFrame = double(frames(k).z)./2;
        currentFrame = currentFrame(mask);
        depthVal(k,1) = mean(currentFrame(:));
    end
    
    figure(resultsFigNum);
    subplot(311); plot(apdVal,depthVal); title(myTitle); xlabel('APD values'); ylabel('RTD values [mm]'); grid minor;hold on;
    subplot(312); plot(apdVal,deltaDepth); title(myTitle); xlabel('APD values'); ylabel('RTD difference [mm]'); grid minor; xlim([apdVal(1),apdVal(end)]);hold on;
    subplot(313); plot(apdVal,temps); title(myTitle); xlabel('APD values'); ylabel('APD temperature [deg]'); grid minor;hold on;
end
figure(resultsFigNum+10); imagesc(imfuse(mask,frames(1).i));

figure(resultsFigNum);
subplot(311);grid minor;
subplot(312);grid minor;
subplot(313);grid minor;