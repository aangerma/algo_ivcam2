function [loadSingle] = loadSingleScene()
global runParams;
if ~isempty(runParams) && isfield(runParams,'loadSingleScene')
    loadSingle = runParams.loadSingleScene;
else
    loadSingle = 0;
end

end

