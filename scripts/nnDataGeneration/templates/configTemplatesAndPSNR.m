% recordingsPath = 'X:\Data\IvCam2\NN\DCOR\IRFullRange8G';
% testName = 'depth_l1_augmented_adam';

function [regs,luts] = configTemplatesAndPSNR(recordingsPath,testName,regs,luts,printConfiguration)
% configTemplates Receives:
% recordingsPath     - Directory of the bucketed recordings.
% testName           - The name of the optimization procedure(Folder that exists in the psnr dirs). 
% regs               - A struct in which to write the configuration.
% printConfiguration - If true, print the fields and values.
%
% The method writes the template regs and the psnr regs(Template configuration depends on the psnr configuration). 

Mcw = 3600;                                      % This is an approximation. todo - use the cw recordings. mean(ivs.slow(ivs.slow>0));% Average of the slow channel in the CW recording (Remove zeros)
[psnrRegs, ~] = Calibration.psnrTableGen(Mcw);   % Function written by YoniC. Gets the PSNR regs.
for fn = fieldnames(psnrRegs.DCOR)'% copy to these regs the psnr configuration
   regs.DCOR.(fn{1}) = psnrRegs.DCOR.(fn{1});
end
% My current template configuration assumes a sample rate of 8 and code
% length of 64
regs.GNRL.codeLength = 64;
regs.GNRL.sampleRate = 8;
regs.GNRL.tmplLength = regs.GNRL.codeLength*regs.GNRL.sampleRate;

regs.DCOR.tmplMode = 0;                          % Set to 0 - only the psnr index is used to pick the template.
regs.DCOR.fineCorrRange = 16;                    % Half of the fine correlation length (rounded down). 
regs.DCOR.decRatio = 2;                          % The decimation ration of the data before the coarse filter(number of right shifts). 


%% The templates themselves
codevec = kron(Codes.propCode(regs.GNRL.codeLength,1),ones(regs.GNRL.sampleRate,1)); 
nF =  length(codevec); 
nC =  bitshift(nF,-double(regs.DCOR.decRatio));
nTemplates = 64;
binTemplates = repmat(codevec,1,nTemplates);
binTemplates = uint8(round(min(1,max(0,binTemplates))*7));% This is what the fine template would have bin were we using the binary configuration.
tmplC = bitshift(uint8(permute(sum(reshape(binTemplates,2^regs.DCOR.decRatio,[],size(binTemplates,2))),[2 3 1])),-double(regs.DCOR.decRatio));
% replicate to 256
tmplC = tmplC(mod(0:255,nC)+1,:);
% Coarse templates should remain a derivation of the binary template
luts.DCOR.tmpltCrse = typecast(uint8(sum(bsxfun(@bitshift,reshape(tmplC(:),2,[]),[0;4]))),'uint32');

% Fine templates are loaded from training results files.
tmplFine = uint8(loadAndConfigFineTemplates(recordingsPath,testName));
tmplFine = tmplFine(mod(0:1023,nF)+1,:); % Replicate to 1024
% rotate (asic bug)
tmplFine  = circshift(tmplFine ,[nF-16,-16]);
luts.DCOR.tmpltFine = typecast(uint8(sum(bsxfun(@bitshift,reshape(tmplFine(:),2,[]),[0;4]))),'uint32');

if printConfiguration
    fprintf('\nregs.DCOR:\n')
    disp(regs.DCOR)
    fprintf('\nluts.DCOR:\n')
    disp(luts.DCOR)
end

end
function [fineTemplates] = loadAndConfigFineTemplates(recordingsPath,testName)
rangeDirs = dir(recordingsPath);                           
rangeDirs = rangeDirs(3:end);                               % Filter '.' and '..'
rangeDirs = rangeDirs([rangeDirs.isdir]);%rangeDirs Contains a list of the directories - each directory has the recordings for a specific range of psnr/ir

psnrVals = cell2mat(cellfun(@(p) str2num(p(end-1:end)) ,{rangeDirs.name},'UniformOutput',false)); % Extract the psnr value from each foldr name

results = cellfun(@(p) load(fullfile(recordingsPath,p,testName,'results.mat')),{rangeDirs.name},'UniformOutput',false); % Load results per range
% Add the results to the rangeDir struct array 
[rangeDirs(:).results] = deal(results{:});
s = [rangeDirs(:).results];                      % Get rangeDirs(:).results(:).BestSoFar(:).val(:).template
s = [s(:).BestSoFar];                            % Get rangeDirs(:).results(:).BestSoFar(:).val(:).template
s = [s(:).val];                                  % Get rangeDirs(:).results(:).BestSoFar(:).val(:).template
templatesLearned = [s(:).template];              % Get rangeDirs(:).results(:).BestSoFar(:).val(:).template
psnrFullVec = (0:63)';                           % The values of the desired psnrs
nearestId = knnsearch(psnrVals',psnrFullVec);    % The id of the template taken for each psnr value. Using nearest neighbour interpolation.
fineTemplates = templatesLearned(:,nearestId);   % Getting the nearest template.
end
