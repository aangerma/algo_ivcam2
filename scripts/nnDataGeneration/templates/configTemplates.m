% this function loads the resulting templates from the optimization process
% and set the regs value according to the IR/PSNR ranges.

% recordingsPath = 'X:\Data\IvCam2\NN\DCOR\IRFullRange';
% testName = 'cross_entropy_plus_min_z';

function [regs] = configTemplates(recordingsPath,testName,regs)
%CONFIGTEMPLATES Receives the directory of the bucketed recordings. The
%name of the optimization procedure. and a regs struct.
% It set the following fields in the struct:
% IRMap
%
%
regs.DCOR.decRatio = 4;
regs.DCOR.irStartLUT = ?
regs.DCOR.irLUTExp = ?
regs.DCOR.irMap = ?
regs.DCOR.ambStartLUT = ?
regs.DCOR.ambLUTExp = ?
regs.DCOR.psnr = ?
regs.DCOR.tmplMode = 0;
regs.DCOR.fineCorrRange = 0;

% Todo - move to boot calcs

luts.DCOR.templates = loadAndConfigFineTemplates(recordingsPath,testName);
end
function [templates] = loadAndConfigFineTemplates(recordingsPath,testName)
rangeDirs = dir(recordingsPath);
rangeDirs = rangeDirs(3:end);
rangeDirs = rangeDirs([rangeDirs.isdir]);%rangeDirs: Contains a list of the directories - each directory has the recordings for a specific range of psnr/ir
% Load results per range
results = cellfun(@(p) load(fullfile(recordingsPath,p,testName,'results.mat')),{rangeDirs.name},'UniformOutput',false);
% Add the results to the rangeDir struct array
[rangeDirs(:).results] = deal(results{:});
s = [rangeDirs(:).results];
s = [s(:).Learned];
s = [s(:).val];
templates = [s(:).template];
[h,w]  = size(templates);
templates = vec([templates,zeros(h,64-w);zeros(1024-h,64)]);
end
