function [dbPath] = getDbPathByType(dbType)
switch dbType
    case 'iq'
        dbPath = 'X:\IVCAM2_calibration _testing\dbDocumentation\IqDb.xlsx';
    case 'robot'
        dbPath = 'X:\IVCAM2_calibration _testing\dbDocumentation\robotDb.xlsx';
    case 'dataCollection'
        dbPath = 'X:\IVCAM2_calibration _testing\dbDocumentation\dataCollectionDb.xlsx';
    case 'dataCollectionAged'
        dbPath = 'X:\IVCAM2_calibration _testing\dbDocumentation\dataCollectionDbAged.xlsx';
    otherwise
        error(['No such dats base: ' dbType]);
end
end

