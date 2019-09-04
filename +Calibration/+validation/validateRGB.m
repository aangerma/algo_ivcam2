function [results,frames,dbg] = validateRGB( hw, calibParams,runParams, fprintff)
% set LR preset
hw.setPresetControlState(1);
hw.cmd('mwd a00e18b8 a00e18bc ffff0000 // JFILinvMinMax');
hw.cmd('mwd a0020834 a0020838 ffffffff // DCORcoarseMasking_002');
hw.shadowUpdate;

pause(5);
% hw.startStream([],[],calibParams.colorRes);

depthFrame = hw.getFrame(calibParams.validationConfig.rgb.numOfFrames);
rgbFrame  = hw.getColorFrame();

[ ~,b] = hw.cmd('RGB_INTRINSICS_GET');
intr = typecast(b,'single');
Krgb = eye(3);
% Verify the correct K for resolution used
Krgb([1,5,7,8,4]) = intr([calibParams.startIxRgb:calibParams.startIxRgb+3,1]);%intr([6:9,1]);
[ ~,b] = hw.cmd('RGB_EXTRINSICS_GET');
extr = typecast(b,'single');
Rrgb = reshape(extr(1:9),[3 3])';
Trgb = extr(10:12)';

params.rgbPmat = Krgb*[Rrgb Trgb];
params.camera = struct('zMaxSubMM',hw.z2mm,'K',hw.getIntrinsics);
params.sampleZFromWhiteCheckers = calibParams.validationConfig.sampleZFromWhiteCheckers;
params.validateOnCenter = calibParams.validationConfig.validateOnCenter;
params.roi = calibParams.validationConfig.roi4ValidateOnCenter;
params.isRoiRect = calibParams.validationConfig.gidMaskIsRoiRect;

[~, resultsUvMap,dbg] = Validation.metrics.uvMapping(depthFrame, params, rgbFrame);

[resultsLineFit] = Calibration.aux.calcLineDistortion({dbg.vertices},double(Krgb),dbg.gridSize);
fields = fieldnames(resultsLineFit);
for k = 1:length(fields)
    if contains(fields{k},'3D')
        resultsLineFit = rmfield(resultsLineFit,fields{k});
        continue;
    end
    newName = strcat(fields{k},'_RGB');
    results.(newName) = resultsLineFit.(fields{k});
end

results.uvMapRmse = resultsUvMap.rmse;
results.uvMapMaxErr = resultsUvMap.maxErr;
results.uvMapMaxErr95 = resultsUvMap.maxErr95;
results.uvMapMinErr = resultsUvMap.minErr;
frames = depthFrame;
frames.color = rgbFrame;
%%
% Erase at last - just debug
%{
% cornersIr = Validation.aux.findCheckerboard(rot90(frame.i,2));
ir = rot90(depthFrame.i,2);
z = rot90(depthFrame.z,2);
[cornersIr,~] = Calibration.aux.CBTools.findCheckerboardFullMatrix(ir,[],[],[],calibParams.nonRectangleFlagRGB);
%{
figure; imagesc(ir);
hold on;
 a = reshape(cornersIr,[],2);
scatter(a(:,1),a(:,2),'r');
%}
gridPointsIr = reshape(cornersIr,[],2);
verCorners = Validation.aux.pointsToVertices(gridPointsIr-1,z,camera);
[cornersRGB,~] = Calibration.aux.CBTools.findCheckerboardFullMatrix(rgbFrame(1).color,[],[],[],calibParams.nonRectangleFlagRGB);
%{
figure; imagesc(rgbFrame(1).color);
hold on;
 a = reshape(cornersRGB,[],2);
scatter(a(:,1),a(:,2),'r');
%}

uv = rgbPmat * [verCorners ones(size(verCorners,1),1)]';
u = (uv(1,:)./uv(3,:))';
v = (uv(2,:)./uv(3,:))';


idx = ~isnan(reshape(cornersRGB,[],2)) & ~isnan(reshape(cornersIr,[],2));
idx = idx(:,1);
figure; imagesc(rgbFrame(1).color); hold on;
sampledCornerRGB = reshape(cornersRGB,[],2);

scatter(sampledCornerRGB(:,1),sampledCornerRGB(:,2),'g');
plot(u,v, 'xr');
uvMap = [u,v];
uvMap = uvMap(idx,:);
sampledCornerRGB = sampledCornerRGB(idx,:);
errs = sampledCornerRGB - uvMap;
rms = sqrt(mean(sum((errs').^2)));
%}
end

