function [metaDataStruct] = loadIpDevRscFile(binData,rscStructure)
if(~exist('rscStructure','var'))
    warning('off','MATLAB:table:ModifiedAndSavedVarnames')
    rscTable = readtable(fullfile(fileparts(mfilename('fullpath')),'L500recordingStatusTableDefinition.xlsx'));
    rscStructure = table2struct(rscTable);
end
s = Stream(binData);
for k = 1:length(rscStructure)
    sk = rscStructure(k);
    type = sk.format;
    if isempty(type)
        arraysize = sk.Size_Bytes_;
        s.getNext('uint8',arraysize);
        continue;
    end
    arraysize = sk.Size_Bytes_;
    switch type
        case {'uint32'}
            val=s.getNextUint32();
        case {'char'}
            val=s.getNext('uint8',arraysize);
            val = dec2hex(val);
            val =reshape(val(1:4,:),1,[]);
        case {'float'}
            val=s.getNextSingle();
        case {'3x3 float'}
            val=s.getNext('single',9);
            val = reshape(val,3,3)';
        case {'3x1 float'}
            val=s.getNext('single',3);
        case {'1x5 float'}
            val=s.getNext('single',5)';
        case {'1x4 float'}
            val=s.getNext('single',4);
        otherwise
            error('Undefined type');
    end
    fieldName = rscStructure(k).Description;
    fieldName(isspace(fieldName)) = '_';
    metaDataStruct.(fieldName) = val;
end
end

