function [ignoreOutputInvalidation] = getIgnoreOutputValidationFlag()
global runParams;
if ~isempty(runParams) && isfield(runParams,'ignoreOutputInvalidation')
    ignoreOutputInvalidation = runParams.ignoreOutputInvalidation;
else
    ignoreOutputInvalidation = 0;
end

end

