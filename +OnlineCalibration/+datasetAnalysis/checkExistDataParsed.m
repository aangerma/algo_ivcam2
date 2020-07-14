function [isParsed,dataOut] = checkExistDataParsed(dbType)
dataOut = struct();
isParsed = false;
basePath = 'X:\IVCAM2_calibration _testing\dbDocumentation';
switch dbType
    case 'iq'
        folderName = 'iqDataParsed';
    case 'robot'
        folderName = 'robotDataParsed';
    case 'dataCollection'
        folderName = 'dataCollectionDataParsed';
    case 'dataCollectionAged'
        folderName = 'dataCollectionAgedDataParsed';
    otherwise
        error(['No such dats base: ' dbType]);
end
dirData = dir(fullfile(basePath,folderName));
if ~isempty(dirData) && dirData(end).bytes > 0
    isParsed = true;
    dataOut = load(fullfile(basePath,folderName,dirData(end).name),'paramsAll','acInputDataAll','framePathsAll','lutPathsAll','unitSnAll');
end
end
