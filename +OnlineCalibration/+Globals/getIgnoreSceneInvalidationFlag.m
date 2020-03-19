function [ignoreSceneInvalidation] = getIgnoreSceneInvalidationFlag()
global runParams;
if ~isempty(runParams) && isfield(runParams,'ignoreSceneInvalidation')
    ignoreSceneInvalidation = runParams.ignoreSceneInvalidation;
else
    ignoreSceneInvalidation = 0;
end

end

