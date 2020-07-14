function [isValid] = checkInputParameters(dsmRegs,acData,params)
% Checks for specific errors we saw across the datasets
% Currently checks for:
% valid dsm values
isValid = 1;
fnames = fieldnames(dsmRegs);
for i = 1:numel(fnames)
    isValid = isValid && ~isnan(dsmRegs.(fnames{i}));
end
validAcData = ~isfield(params,'acData') || isempty(params.acData) ||  params.acData.flags(1) == 1;
isValid = isValid && validAcData;

end

