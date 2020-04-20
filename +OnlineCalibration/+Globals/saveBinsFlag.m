function [saveBins] = saveBinsFlag()
global runParams;
if ~isempty(runParams) && isfield(runParams,'saveBins')
    saveBins = runParams.saveBins;
else
    saveBins = 1;
end

end

