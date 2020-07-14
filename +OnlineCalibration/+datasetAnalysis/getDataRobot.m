function [paramsOut,acInputData,framePaths,lutPaths,unitSn,queryParamsVals,originalParamsOut] = getDataRobot(dbPath,queryParams)
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
lutPaths =  Tnew.lutLink;
unitSn = Tnew.serial;
for k = 1:numel(Tnew.frameLink)
    load(fullfile(framePaths{k}),'params','dbg','originalParams');
    [paramsOut(k)] = parseRobotToAlgoInputs(params);
    acInputData(k) = dbg.dataForACTableGeneration;
    originalParamsOut(k) = originalParams;
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

function [paramsOut] = parseRobotToAlgoInputs(allParams)
paramsOut.rgbRes = allParams.rgbRes;
paramsOut.depthRes = allParams.depthRes;
paramsOut.Krgb = allParams.Krgb;
paramsOut.Kdepth = allParams.Kdepth;
paramsOut.rgbDistort = allParams.rgbDistort;
paramsOut.zMaxSubMM = allParams.zMaxSubMM;
paramsOut.Trgb = allParams.Trgb;
paramsOut.Rrgb = allParams.Rrgb;
paramsOut.xAlpha = allParams.xAlpha;
paramsOut.yBeta = allParams.yBeta;
paramsOut.zGamma = allParams.zGamma;
paramsOut.rgbPmat = allParams.rgbPmat;
end