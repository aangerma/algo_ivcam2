function [] = updateDb(dbType)
if iscell(dbType)
    for i = 1:numel(dbType)
        updateSingleDb(dbType{i});
    end
else
    updateSingleDb(dbType);
end

end

function updateSingleDb(dbType)
    switch dbType
        case 'iq'
            OnlineCalibration.datasetAnalysis.iqDB2Excel();
        case 'robot'
            OnlineCalibration.datasetAnalysis.robotDB2Excel();
        case 'dataCollection'
            OnlineCalibration.datasetAnalysis.dataCollectionDB2Excel('normal');
        case 'dataCollectionAged'
            OnlineCalibration.datasetAnalysis.dataCollectionDB2Excel('aged');
        otherwise
            error(['No such dats base: ' dbType]);
    end
end