function [paramsOut,acInputData,framePaths,lutPaths,unitSn,queryParamsVals] = getDataInForTest(dbType,queryParams)
dbPaths = {};

for k = 1:numel(dbType)
    dbPaths{k} = OnlineCalibration.datasetAnalysis.getDbPathByType(dbType{k});
end
paramsOut = [];
acInputData = [];
if nargin < 2
    queryParams = [];
end
if iscell(dbPaths)
    paramsOut = [];
    acInputData = [];
    framePaths = [];
    lutPaths = [];
    unitSn = [];
    queryParamsVals = [];
    for k = 1:numel(dbPaths)
        [paramsOutTemp,acInputDataTemp,framePathsTemp,lutPathsTemp,unitSnTemp,queryParamsValsTemp,~] = getDataInForTestInternal(dbPaths{k},queryParams);
        paramsOut = [paramsOut,paramsOutTemp];
        acInputData = [acInputData,acInputDataTemp];
        framePaths = [framePaths;framePathsTemp];
        lutPaths = [lutPaths;lutPathsTemp];
        unitSn = [unitSn;unitSnTemp];
        queryParamsVals = [queryParamsVals,queryParamsValsTemp];
        %         originalParamsOut = [originalParamsOut; originalParamsOutTemp];
    end
else
    [paramsOut,acInputData,framePaths,lutPaths,unitSn,queryParamsVals,~] = getDataInForTestInternal(dbPaths,queryParams);
end

end


function [paramsOut,acInputData,framePaths,lutPaths,unitSn,queryParamsVals,originalParamsOut] = getDataInForTestInternal(dbPath,queryParams)
if contains(dbPath,'Iq')
    [paramsOut,acInputData,framePaths,lutPaths,unitSn,queryParamsVals] = OnlineCalibration.datasetAnalysis.getDataIq(dbPath,queryParams);
    originalParamsOut = [];
end
if contains(dbPath,'Collection')
    [paramsOut,acInputData,framePaths,lutPaths,unitSn,queryParamsVals] = OnlineCalibration.datasetAnalysis.getDataCollection(dbPath,queryParams);
    originalParamsOut = [];
end
if contains(dbPath,'robot')
    [paramsOut,acInputData,framePaths,lutPaths,unitSn,queryParamsVals,originalParamsOut] = OnlineCalibration.datasetAnalysis.getDataRobot(dbPath,queryParams);
end
end