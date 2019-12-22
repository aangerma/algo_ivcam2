function [results,frames,dbgReg] = validateRGB( hw, calibParams,runParams, fprintff,depthFrame,rgbFrame)
if ~exist('depthFrame','var') || ~exist('rgbFrame','var')
        % set LR preset
    hw.setPresetControlState(1);
    hw.cmd('mwd a00e18b8 a00e18bc ffff0000 // JFILinvMinMax');
    hw.cmd('mwd a0020834 a0020838 ffffffff // DCORcoarseMasking_002');
    hw.shadowUpdate;

    pause(5);
    % hw.startStream([],[],calibParams.rgb.imSize);

    depthFrame = hw.getFrame(calibParams.validationConfig.rgb.numOfFrames);
    rgbFrame  = hw.getColorFrame();
end
[ ~,b] = hw.cmd('RGB_INTRINSICS_GET');
intr = typecast(b,'single');
Krgb = eye(3);
% Verify the correct K for resolution used
Krgb([1,5,7,8,4]) = intr([calibParams.validationConfig.rgb.startIxRgb:calibParams.validationConfig.rgb.startIxRgb+3,1]);%intr([6:9,1]);
drgb = intr(calibParams.validationConfig.rgb.startIxRgb+4:calibParams.validationConfig.rgb.startIxRgb+8);

[ ~,b] = hw.cmd('RGB_EXTRINSICS_GET');
extr = typecast(b,'single');
Rrgb = reshape(extr(1:9),[3 3])';
Trgb = extr(10:12)';
%%
params.rgbPmat = Krgb*[Rrgb Trgb];
params.camera = struct('zMaxSubMM',hw.z2mm,'K',hw.getIntrinsics);
params.sampleZFromWhiteCheckers = calibParams.validationConfig.sampleZFromWhiteCheckers;
params.validateOnCenter = calibParams.validationConfig.validateOnCenter;
params.roi = calibParams.validationConfig.roi4ValidateOnCenter;
params.isRoiRect = calibParams.validationConfig.gidMaskIsRoiRect;
params.rgbDistort = drgb;
params.Krgb = Krgb;
params.Krgbn = du.math.normalizeK(Krgb,flip(size(rgbFrame.color)));
%%
if params.sampleZFromWhiteCheckers
    [resultsWht,dbgWht] = runUVandLF( depthFrame, params, rgbFrame.color, 'Wht');
    params.sampleZFromWhiteCheckers = 0;
    %%
    ff = Calibration.aux.invisibleFigure();
    imagesc(rgbFrame.color);hold on;
    scatter(dbgWht.sampledCornerRGB(:,1),dbgWht.sampledCornerRGB(:,2),'w');
    plot(dbgWht.uvMap(:,1),dbgWht.uvMap(:,2),'xk');
    quiver(dbgWht.uvMap(:,1),dbgWht.uvMap(:,2), dbgWht.sampledCornerRGB(:,1)-dbgWht.uvMap(:,1),dbgWht.sampledCornerRGB(:,2)-dbgWht.uvMap(:,2), 'r');
    title('Validation RGB UV mapping image: white is sampled and black is mapped points - for z sampled from white');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Validation','rgbUvMapImageFromWht',1);
end
[resultsReg,dbgReg] = runUVandLF( depthFrame, params, rgbFrame.color, 'Reg');
%%
ff = Calibration.aux.invisibleFigure();
imagesc(rgbFrame.color);hold on;
scatter(dbgReg.sampledCornerRGB(:,1),dbgReg.sampledCornerRGB(:,2),'w');
plot(dbgReg.uvMap(:,1),dbgReg.uvMap(:,2),'xk');
quiver(dbgReg.uvMap(:,1),dbgReg.uvMap(:,2), dbgReg.sampledCornerRGB(:,1)-dbgReg.uvMap(:,1),dbgReg.sampledCornerRGB(:,2)-dbgReg.uvMap(:,2), 'r');
title('Validation RGB UV mapping image: white is sampled and black is mapped points - for z sampled from corners(reg)');
Calibration.aux.saveFigureAsImage(ff,runParams,'Validation','rgbUvMapImageFromCorner',1);

if exist('resultsWht','var')
    results = Validation.aux.mergeResultStruct(resultsReg,resultsWht);
else
    results = resultsReg;
end
frames = depthFrame;
frames.color = rgbFrame.color;

end

function [results] = arrangResultStruct( resultsLineFit,resultsUvMap, postFix)
results.(strcat('lineFitRmsErrHor2dRGB',postFix)) = resultsLineFit.lineFitRmsErrorTotal_h;
results.(strcat('lineFitRmsErrVer2dRGB',postFix)) = resultsLineFit.lineFitRmsErrorTotal_v;
results.(strcat('lineFitMaxErrHor2dRGB',postFix)) = resultsLineFit.lineFitMaxErrorTotal_h;
results.(strcat('lineFitMaxErrVer2dRGB',postFix)) = resultsLineFit.lineFitMaxErrorTotal_v;
results.(strcat('uvMapRmse',postFix)) = resultsUvMap.rmse;
results.(strcat('uvMapMaxErr',postFix)) = resultsUvMap.maxErr;
results.(strcat('uvMapMaxErr95',postFix)) = resultsUvMap.maxErr95;
results.(strcat('uvMapMinErr',postFix)) = resultsUvMap.minErr;
end


function [results,dbg] = runUVandLF( depthFrame, params, rgbFrame, postFix)
[~, resultsUvMap,dbg] = Validation.metrics.uvMapping(depthFrame, params, rgbFrame);
pts = cat(3,dbg.cornersRGB(:,:,1),dbg.cornersRGB(:,:,2),zeros(size(dbg.cornersRGB,1),size(dbg.cornersRGB,2)));
pts = Calibration.aux.CBTools.slimNans(pts);
if isfield(params,'rgbDistort')
    invd = du.math.fitInverseDist(params.Krgbn,params.rgbDistort);
    pixsUndist = du.math.distortCam(reshape(pts(:,:,1:2),[],2)', params.Krgb, invd);
    ptsUndist = cat(3,reshape(pixsUndist',size(pts,1),size(pts,2),[]),pts(:,:,3));
    pts = ptsUndist;
end
[resultsLineFit] = Validation.metrics.get3DlineFitErrors(pts);
[results] = arrangResultStruct( resultsLineFit,resultsUvMap, postFix);
end