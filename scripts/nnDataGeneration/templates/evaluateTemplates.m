% This script loads the result file from the tensorflow training procedure and summarize the results.

% Let us define the head directory in which lies the range finder
% recordings splitted into folders based on their IR/PSNR values. In
% addition, the name of the test that was used to output these results
% should be noted.

recordingsPath = 'X:\Data\IvCam2\NN\DCOR\IRFullRange';
testName = 'cross_entropy_plus_min_z';

rangeDirs = dir(recordingsPath);
rangeDirs = rangeDirs(3:end);
rangeDirs = rangeDirs([rangeDirs.isdir]);%rangeDirs: Contains a list of the directories - each directory has the recordings for a specific range of psnr/ir

% Load results per range
results = cellfun(@(p) load(fullfile(recordingsPath,p,testName,'results.mat')),{rangeDirs.name},'UniformOutput',false);
% Add the results to the rangeDir struct array
[rangeDirs(:).results] = deal(results{:});

%%%%%%%%%
% Add the range to the struct as well
% todo
%%%%%%%%%

% Present the results:

% Plot the errors per range per template per phase( train/validation)

errors = {'exact_sample_acc','mean_z_error'};
title_vec = {'Exact Sample Acc Per Range','Mean Z Error'};
ylab_vec = {'Percentage','mm'};

tempNames = {'Binary','Avg','Learned'};
modeNames = {'train','val'};
% Define a cell which will convert to table. The columns are -
% [error,range,binary,avg,learned]
errCell = cell(numel(errors)*numel(rangeDirs),2+numel(tempNames));

for errI = 1:numel(errors)
    
    err = errors{errI};
    combin = combvec(1:numel(modeNames),1:numel(tempNames));
    mId = combin(1,:);
    tId = combin(2,:);

    legends = cell(1,size(combin,2));
    barData = zeros(numel(rangeDirs),size(combin,2));
    for i = 1:numel(tId)
        s = [rangeDirs(:).results];
        s = [s(:).(tempNames{tId(i)})];
        s = [s(:).(modeNames{mId(i)})];
        barData(:,i) = [s(:).(err)];
        % Get the bar data per combination
        legends{i} = [tempNames{tId(i)},' ',modeNames{mId(i)}];
       
        
    end
    rowsInd = 1 + (errI-1)*numel(rangeDirs):errI*numel(rangeDirs);
    errCell(rowsInd,1) = {err};
    errCell(rowsInd,2) = {rangeDirs(:).name}';
    errCell(rowsInd,3:5) = num2cell(barData(:,2:2:2*numel(tempNames)));
    
    figure
    
    hb = bar( barData, 'grouped');
    title(title_vec{errI})
    xticklabels(strrep({rangeDirs(:).name}, '_', ' '))
    ylabel(ylab_vec{errI})
    legend(legends)
    
end


% Show the validation data as a table per error.
% The rows are the error criteria per range, the columns are the templates
T = cell2table(errCell,...
    'VariableNames',{'Error' 'Range' 'Binary' 'Average' 'Learned'});
disp(T)
