function [results,frames,dbgWht] = validateRGB( hw, calibParams,runParams, fprintff)
% set LR preset
hw.setPresetControlState(1);
hw.cmd('mwd a00e18b8 a00e18bc ffff0000 // JFILinvMinMax');
hw.cmd('mwd a0020834 a0020838 ffffffff // DCORcoarseMasking_002');
hw.shadowUpdate;

pause(5);
% hw.startStream([],[],calibParams.rgb.imSize);

depthFrame = hw.getFrame(calibParams.validationConfig.rgb.numOfFrames);
rgbFrame  = hw.getColorFrame();

[ ~,b] = hw.cmd('RGB_INTRINSICS_GET');
intr = typecast(b,'single');
Krgb = eye(3);
% Verify the correct K for resolution used
Krgb([1,5,7,8,4]) = intr([calibParams.validationConfig.rgb.startIxRgb:calibParams.validationConfig.rgb.startIxRgb+3,1]);%intr([6:9,1]);
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
%%
if params.sampleZFromWhiteCheckers
    [~, resultsUvMapWht,dbgWht] = Validation.metrics.uvMapping(depthFrame, params, rgbFrame.color);
    [resultsLineFitWht] = Calibration.aux.calcLineDistortion({dbgWht.vertices},double(Krgb),dbgWht.gridSize);
    [resultsWht] = arrangResultStruct( resultsLineFitWht,resultsUvMapWht, 'Wht');
    params.sampleZFromWhiteCheckers = 0;
    
    ff = Calibration.aux.invisibleFigure();
    imagesc(rgbFrame.color);hold on;
    scatter(dbgWht.sampledCornerRGB(:,1),dbgWht.sampledCornerRGB(:,2),'g');
    plot(dbgWht.uvMap(:,1),dbgWht.uvMap(:,2),'xr');
    title('Validation RGB UV mapping image: green is sampled and red is mapped points - for z sampled from white');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Validation','rgbUvMapImageFromWht',1);
end
[~, resultsUvMapReg,dbgReg] = Validation.metrics.uvMapping(depthFrame, params, rgbFrame.color);
[resultsLineFitReg] = Calibration.aux.calcLineDistortion({dbgReg.vertices},double(Krgb),dbgReg.gridSize);
[resultsReg] = arrangResultStruct( resultsLineFitReg,resultsUvMapReg, 'Reg');

ff = Calibration.aux.invisibleFigure();
imagesc(rgbFrame.color);hold on;
scatter(dbgReg.sampledCornerRGB(:,1),dbgReg.sampledCornerRGB(:,2),'g');
plot(dbgReg.uvMap(:,1),dbgReg.uvMap(:,2),'xr');
title('Validation RGB UV mapping image: green is sampled and red is mapped points - for z sampled from corners(reg)');
Calibration.aux.saveFigureAsImage(ff,runParams,'Validation','rgbUvMapImageFromCorner',1);

if exist('resultsWht','var')
    results = Validation.aux.mergeResultStruct(resultsReg,resultsWht);
else
    results = resultsReg;
end
frames = depthFrame;
frames.color = rgbFrame.color;

end


function [newStr] = editStr( origStr,string2erase,string2add)
    newStr = erase(origStr,string2erase);
    newStr = strcat(newStr,string2add);
end

function [results] = arrangResultStruct( resultsLineFit,resultsUvMap, postFix)
fields = fieldnames(resultsLineFit);
for k = 1:length(fields)
    if contains(fields{k},'3D')
        resultsLineFit = rmfield(resultsLineFit,fields{k});
        continue;
    end
    string2erase = 'ErrorTotalHoriz2D';
    if contains(fields{k},string2erase)
        string2add = 'ErrHor2dRGB';
        [newName] = editStr( fields{k},string2erase,string2add);
        results.(strcat(newName,postFix)) = resultsLineFit.(fields{k});
         continue;
    end
    string2erase = 'ErrorTotalVertic2D';
    if contains(fields{k},string2erase)
        string2add = 'ErrVer2dRGB';
        [newName] = editStr( fields{k},string2erase,string2add);
        results.(strcat(newName,postFix)) = resultsLineFit.(fields{k});
        continue;
    end
end

results.(strcat('uvMapRmse',postFix)) = resultsUvMap.rmse;
results.(strcat('uvMapMaxErr',postFix)) = resultsUvMap.maxErr;
results.(strcat('uvMapMaxErr95',postFix)) = resultsUvMap.maxErr95;
results.(strcat('uvMapMinErr',postFix)) = resultsUvMap.minErr;


end
