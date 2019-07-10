% Get data from path
unitNum = 'F9140918';
switch unitNum
    case 'F9140680'
        maskCenterShiftVal = [-70,-20];
    case 'F9140918'
        maskCenterShiftVal = [-45,-20];
    otherwise
        error('No such unit!!!');
end

dataPath = ['X:\Data\gradFilt\' unitNum];
debugMode = 0;
targetReflect = 0.09;%0.0614;
dirInfo = dir(dataPath);
distances = zeros(ceil(length(dirInfo)/2),1)-1;
distCount = 1;
for k = 1:length(dirInfo)
    if dirInfo(k).isdir
        continue;
    end
    if contains(dirInfo(k).name, 'newConfig')
        splittedStr = strsplit(dirInfo(k).name, '_');
        distances(distCount) = str2double(splittedStr{3});
        distCount = distCount + 1;
    end
end
distances(distances == -1) = [];
%%
% Calculate fill rate:
default_fillRate = zeros(length(distances),1);
newConfig_fillRate = zeros(length(distances),1);
params = struct('roi', 0.1, 'isRoiRect', 0, 'roiCropRect', 0, 'maskCenterShift',maskCenterShiftVal);
depthMaxMargin = 10;
for k = 1:length(distances)
    str = sprintf('default_dist_%03d_cm',distances(k));
    default_frames = load(fullfile(dataPath, [str '.mat']));
    str = sprintf('newConfig_dist_%03d_cm',distances(k));
    newConfig_frames = load(fullfile(dataPath, [str '.mat']));
    maxDepth = max([default_frames.frame(10).z(:)./4;newConfig_frames.frame(10).z(:)./4]);
    if debugMode
        mask = Validation.aux.getRoiCircle(size(default_frames.frame(10).z), params);
        figure; subplot(2,1,1); imagesc(imfuse(default_frames.frame(10).z./4,mask), [0,maxDepth+depthMaxMargin]); title(['Default depth at distance ' num2str(distances(k)) 'cm']);impixelinfo;
        subplot(2,1,2); imagesc(imfuse(newConfig_frames.frame(10).z./4,mask), [0,maxDepth+depthMaxMargin]); title(['New configuration depth at distance ' num2str(distances(k)) 'cm']);impixelinfo;
    end
    [default_fillRate(k,1), ~, ~] = Validation.metrics.fillRate(default_frames.frame, params);
    [newConfig_fillRate(k,1), ~, ~] = Validation.metrics.fillRate(newConfig_frames.frame, params);
end
%%
% Plot results
ix90default = find(default_fillRate>90,1,'last');
[a,b] = getLinearCoeffs2Pts([distances(ix90default),default_fillRate(ix90default)],[distances(ix90default+1),default_fillRate(ix90default+1)]);
dist90default = (90-b)/a;
ix90newConfig = find(newConfig_fillRate>90,1,'last');
[a,b] = getLinearCoeffs2Pts([distances(ix90newConfig),newConfig_fillRate(ix90newConfig)],[distances(ix90newConfig+1),newConfig_fillRate(ix90newConfig+1)]);
dist90newConfig = (90-b)/a;

maxRbgDistDefault = dist90default*sqrt(0.8/targetReflect);
maxRbgDistnewConfig = dist90newConfig*sqrt(0.8/targetReflect);

figure;
plot(distances,default_fillRate,distances,newConfig_fillRate, distances, repelem(90, length(distances))); title(['Unit #' num2str(unitNum)]); xlabel('Distance [cm]'); ylabel('Fill Rate'); legend(['Default Configuartion (estimated ' num2str(maxRbgDistDefault,'%4.1f') ' cm)'],['New Configuration (estimated ' num2str(maxRbgDistnewConfig,'%4.1f') ' cm)']);

grid minor;
%%
function [a,b] = getLinearCoeffs2Pts(pt1,pt2)
% y = ax+b
a = (pt1(2) - pt2(2))/(pt1(1)-pt2(1));
b = pt1(2) - a*pt1(1);
end