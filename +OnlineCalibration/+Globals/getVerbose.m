function [verbose] = getVerbose()
global runParams;
if ~isempty(runParams) && isfield(runParams,'verbose')
    verbose = runParams.verbose;
else
    verbose = 1;
end

end

