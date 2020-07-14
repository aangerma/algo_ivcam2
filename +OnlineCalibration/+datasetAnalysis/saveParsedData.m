function [savedFullPath] = saveParsedData(dbType,fileName,paramsAll,acInputDataAll,framePathsAll,lutPathsAll,unitSnAll,queryParamsValsAll)
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
savedFullPath = fullfile(basePath,folderName,[dbType fileName '.mat']);
save(savedFullPath,'paramsAll','acInputDataAll','framePathsAll','lutPathsAll','unitSnAll','queryParamsValsAll');
end

