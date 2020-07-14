function [sceneResults] = calcLutFromDir(sceneDir,params)
global runParams;
runParams.loadSingleScene = 1;
sceneResults = struct;
sceneResults.cbFullPath = fullfile(sceneDir,'CheckerBoard');
sceneResults.sceneFullPath = fullfile(sceneDir,'Scene');
sceneResults.cbFullPath = fullfile(sceneDir,'CheckerBoard');
if contains(sceneDir,'aged')
    load(fullfile(sceneResults.sceneFullPath,'cameraParams.mat'),'cameraParams');
    params = mergestruct(params,cameraParams);
else
    [params] = OnlineCalibration.aux.getCameraParamsFromRsc(sceneResults.cbFullPath,params);
end
[params.xAlpha,params.yBeta,params.zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(params.Rrgb);
[params] = OnlineCalibration.aux.getParamsForAC(params);

params.targetType = 'checkerboard_Iv2A1';
if contains(sceneDir,'aged')
    params.serial = 'F9440656';
else
    params.serial = strsplit(sceneDir,'\'); params.serial = params.serial{end-2};
end
[params.atcPath,params.accPath,params.calPathValid] = OnlineCalibration.aux.serialToCalDirs(params.serial);
sceneResults.serial = params.serial;
frameCB = OnlineCalibration.aux.loadZIRGBFrames(sceneResults.cbFullPath,[]);
frameCB.z = frameCB.z(:,:,end);
frameCB.i = frameCB.i(:,:,end);
frameCB.yuy2 = frameCB.yuy2(:,:,end);









calData = Calibration.tables.getCalibDataFromCalPath(params.atcPath, params.accPath);
regsDEST.hbaseline = 0;
regsDEST.baseline = -10;
regsDEST.baseline2 = regsDEST.baseline^2;
regs = calData.regs;
regs.DEST = mergestruct(regs.DEST, regsDEST);
dsmRegsOrig = calData.regs.EXTL;
if ~isfield(params,'acData')
    acData = OnlineCalibration.aux.defaultACTable();
    acData.flags = 1;
    dsmRegs = dsmRegsOrig;
else
    acData = params.acData;
    dsmRegs = Utils.convert.applyAcResOnDsmModel(acData, dsmRegsOrig, 'direct');
end
sceneResults.acDataIn = acData;
ind = 0;
[~,cbVerticesOrig,~,ptsRgb] = OnlineCalibration.Metrics.calcUVMappingErr(frameCB,params,0);
tic;
for i = 1:numel(params.factorsVec)
    for j = 1:numel(params.factorsVec)
        acData.hFactor = params.factorsVec(i);
        acData.vFactor = params.factorsVec(j);
        dsmRegs = Utils.convert.applyAcResOnDsmModel(acData, dsmRegsOrig, 'direct');
        [cbVertices,xcb,ycb] = OnlineCalibration.K2DSM.updateVerticesWithNewDSM(cbVerticesOrig,regs,dsmRegsOrig,dsmRegs,params.Kdepth);

        % Fill lut
        ind = ind + 1;
        tempS = struct;
        tempS.time = datestr(datetime('now'));
        tempS.sn = params.serial;
        tempS.distance = nanmean(cbVerticesOrig(:,3))/10;
        tempS.hScale = acData.hFactor;
        tempS.vScale = acData.vFactor;
        if isfield(params,'captureLdd')
            tempS.LDD_Temperature = params.captureLdd;
            tempS.HUM_Temperature = params.captureHumT;
        end
        tempS = Validation.aux.mergeResultStruct(tempS, lutGeometricalMetrics(cbVertices,30,[20,28],xcb,ycb));
        tempS = Validation.aux.mergeResultStruct(tempS, lutUvMetrics(cbVertices,ptsRgb,params));
        sceneResults.lut(ind) = tempS;
    end
end
toc



end
function [results] = lutUvMetrics(gridVertices,ptsRgb,params)
    params.camera = params;
    params.camera.rgbSize = params.rgbRes;
    params.camera.rgbDistortion = params.rgbDistort;
    params.camera.rgbK = params.camera.Krgb;
    
    % Project to RGB
    uv = params.rgbPmat * [gridVertices ones(size(gridVertices,1),1)]';
    u = (uv(1,:)./uv(3,:))';
    v = (uv(2,:)./uv(3,:))';
    uvMap = [u,v];
    uvMapUndist = du.math.distortCam(uvMap', params.Krgb, params.rgbDistort)' + 1;

    uvErr = ptsRgb - uvMapUndist;
    results.geomReprojectErrorUV_rmseAF = sqrt(nanmean(nansum(uvErr.^2,2)));
    results.geomReprojectErrorUV_maxErrAF = max(sqrt(nansum(uvErr.^2,2)));
end
function [results] = lutGeometricalMetrics(gridVertices,squareSize,gridSize,xim,yim)
% GID errors
resultsGid = Validation.aux.gidOnCorners(gridVertices,gridSize,squareSize);
results.gridInterDistance_errorMeanAF = resultsGid.errorMean;
results.gridInterDistance_errorRmsAF = resultsGid.errorRms;
results.gridInterDistance_scaleErrorAF = resultsGid.scaleError;
% Scale errros
resultsDistortion = Validation.aux.distortionOnCorners(gridVertices,gridSize,squareSize);
results.gridDistortion_horzErrorMeanAF = resultsDistortion.horzErrorMean;
results.gridDistortion_vertErrorMeanAF = resultsDistortion.vertErrorMean;
results.gridDistortion_absHorzErrorMeanAF = resultsDistortion.absHorzErrorMean;
results.gridDistortion_vertErrorMeanAF = resultsDistortion.absVertErrorMean;
% 3D linefit
results3D = Validation.aux.get3DlineFitErrors(reshape(gridVertices,[gridSize,3]));
results.gridLineFit_lineFitHorizontalErrorRmsAF = results3D.lineFitHorizontalErrorRms;
results.gridLineFit_lineFitVerticalErrorRmsAF = results3D.lineFitVerticalErrorRms;
% 2D
results2D = Validation.aux.get3DlineFitErrors(reshape([xim,yim,zeros(size(xim))],[gridSize,3]));
results.gridLineFit_lineFit2DHorizontalErrorRmsAF = results2D.lineFitHorizontalErrorRms;
results.gridLineFit_lineFit2DVerticalErrorRmsAF = results2D.lineFitVerticalErrorRms;

end
