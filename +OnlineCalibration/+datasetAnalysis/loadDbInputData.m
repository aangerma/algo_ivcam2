function [dbData] = loadDbInputData(dataBase,dbAnalysisFlags)
queryParams = [];
attributeNames = [];
paramsAll = [];
acInputDataAll = [];
framePathsAll = [];
lutPathsAll = [];
unitSnAll = [];
dbTypeAll = [];
queryParamsValsAll = [];

for k = 1:numel(dataBase)
    if exist('queryParams','var') && ~isempty(queryParams)
        isParsed = false;
    else
        queryParamsValsNow = [];
        [isParsed,dataOut] = OnlineCalibration.datasetAnalysis.checkExistDataParsed(dataBase{k});
        if isParsed
            paramsNow = dataOut.paramsAll;
            acInputDataNow = dataOut.acInputDataAll;
            framePathsNow = dataOut.framePathsAll;
            lutPathsNow = dataOut.lutPathsAll;
            unitSnNow = dataOut.unitSnAll;
        end
    end
    if ~isParsed
        [paramsNow,acInputDataNow,framePathsNow,lutPathsNow,unitSnNow,queryParamsValsNow] = OnlineCalibration.datasetAnalysis.getDataInForTest(dataBase(k),queryParams);
        OnlineCalibration.datasetAnalysis.saveParsedData(dataBase{k},'AllScenes',paramsNow,acInputDataNow,framePathsNow,lutPathsNow,unitSnNow,queryParamsValsNow);
    end
    paramsAll = [paramsAll, paramsNow];
    acInputDataAll = [acInputDataAll, acInputDataNow];
    framePathsAll = [framePathsAll; framePathsNow];
    lutPathsAll = [lutPathsAll; lutPathsNow];
    unitSnAll = [unitSnAll; unitSnNow];
    dbTypeAll = [dbTypeAll;repmat(dataBase{k},size(framePathsNow))];
    if ~isempty(queryParamsValsNow)
        queryParamsValsAll = [queryParamsValsAll, queryParamsValsNow];
    end
end

if  ~isempty(queryParamsValsAll)
    attributeNames = fieldnames(queryParamsValsAll);
end

dbData.paramsAll = paramsAll;
dbData.acInputDataAll = acInputDataAll;
dbData.framePathsAll = framePathsAll;
dbData.lutPathsAll = lutPathsAll;
dbData.unitSnAll = unitSnAll;
dbData.dbTypeAll = dbTypeAll;
dbData.queryParamsValsAll = queryParamsValsAll;
dbData.attributeNames = attributeNames;

if dbAnalysisFlags.shuffleDb
    newOrder = randperm(numel(paramsAll));
    fnames = fieldnames(dbData);
    for f = 1:numel(fnames)
       if numel(dbData.(fnames{f})) == numel(newOrder)
           dbData.(fnames{f}) = dbData.(fnames{f})(newOrder);
       end
    end
end

if dbAnalysisFlags.sortByRes
    dbData = sortByDepthRes(dbData);
end
if dbAnalysisFlags.sortBySerial
    dbData = sortBySerial(dbData);
end

end
function dbData = sortByDepthRes(dbData)
    paramsAll = [dbData.paramsAll];
    depthRes = reshape([paramsAll.depthRes],2,[])';
    
    [~,newOrder] = sort(depthRes(:,1));
    
    fnames = fieldnames(dbData);
    for f = 1:numel(fnames)
        sortAxis = find(size(dbData.(fnames{f})) == numel(newOrder));
        if sortAxis == 1
            dbData.(fnames{f}) = dbData.(fnames{f})(newOrder,:);
        elseif sortAxis == 2
            dbData.(fnames{f}) = dbData.(fnames{f})(:,newOrder);
        end
    end
    
end
function dbData = sortBySerial(dbData)
    [~,newOrder] = sort(dbData.unitSnAll);
    
    fnames = fieldnames(dbData);
    for f = 1:numel(fnames)
        sortAxis = find(size(dbData.(fnames{f})) == numel(newOrder));
        if sortAxis == 1
            dbData.(fnames{f}) = dbData.(fnames{f})(newOrder,:);
        elseif sortAxis == 2
            dbData.(fnames{f}) = dbData.(fnames{f})(:,newOrder);
        end
    end
    
end
