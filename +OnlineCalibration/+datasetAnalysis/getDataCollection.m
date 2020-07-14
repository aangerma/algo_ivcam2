function [paramsOut,acInputData,framePaths,lutPaths,unitSn,queryParamsVals] = getDataCollection(dbPath,queryParams)
T = readtable(dbPath);
Tnew = T;
if nargin > 1 && ~isempty(queryParams)
    if isfield(queryParams,'preset')
        [Tnew] = getTableByCut(queryParams.preset,'preset',Tnew);
    end
    if isfield(queryParams,'serial')
        [Tnew] = getTableByCut(queryParams.serial,'serial',Tnew);
    end
    attributes = fieldnames(queryParams);
    for k = 1:numel(attributes)
        queryParamsVals.(attributes{k}) = Tnew.(attributes{k});
    end
else
    queryParamsVals = [];
end
framePaths = Tnew.frameLink;
lutPaths = Tnew.lutLink;
unitSn = Tnew.serial;
unitCalibPathBase = 'X:\IVCAM2_calibration _testing\unitCalibrationData';
for k = 1:numel(Tnew.frameLink)
    [paramsOut(k)] = parseCollectionToAlgoInputs(Tnew.frameLink{k});
    atcDirData = dir(fullfile(unitCalibPathBase,unitSn{k},'ATC*'));
    accDirData = dir(fullfile(unitCalibPathBase,unitSn{k},'ACC*'));
    [acInputData(k)] = OnlineCalibration.K2DSM.readDataForK2DSMfile(fullfile(unitCalibPathBase,unitSn{k},atcDirData.name),fullfile(unitCalibPathBase,unitSn{k},accDirData.name),1);
end

end

function [Tout] = getTableByCut(cutVals,tableVarName,Tin)
if iscell(cutVals)
    for k = 1:numel(cutVals)
        ix = contains(Tin.(tableVarName),cutVals{k});
        if k == 1
            Tout = Tin(ix,:);
        end
        Tout = [Tout; Tin(ix,:)];
    end
else
    ix = contains(Tin.(tableVarName),cutVals);
    Tout = Tin(ix,:);
end
end

function [paramsOut] = parseCollectionToAlgoInputs(cameraParamsFolder)
if contains(cameraParamsFolder,'aged')
    tempLoad = load(fullfile(cameraParamsFolder,'cameraParams.mat'));
    paramsOut = tempLoad.cameraParams;
    paramsOut.captureHumT = nan;
    paramsOut.captureLdd = nan;
else
    [paramsOut] = OnlineCalibration.aux.getCameraParamsFromRsc(cameraParamsFolder);
end
[paramsOut.xAlpha,paramsOut.yBeta,paramsOut.zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(paramsOut.Rrgb);
end