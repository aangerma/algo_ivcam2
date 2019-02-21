function [frames,coolingStage] = loadDataSet()
dataSetDir = 'X:\Data\IvCam2\temperaturesData\rptCollection\0021';


%% Plot temperature over time graph
iteration = dir(dataSetDir);
iteration = iteration(3:end);
for i = 1:numel(iteration)
        subdir = fullfile(dataSetDir,iteration(i).name);
        [frames{i},coolingStage(i).data] = loadDataSetDir(subdir);
        
end

end

function [frames,coolingStage] = loadDataSetDir(subdir)
    coolingStage = [];
    fnames = dir(subdir);
    fnames = fnames(3:end);
    k = 1;
    for i = 1:numel(fnames)
        fname = fullfile(subdir,fnames(i).name);
        if contains(fname,'coolingLog')
            data = load(fname);
            coolingStage = data.coolingTable;
        elseif contains(fnames(i).name,'frameData')
            data = load(fname);
            frames(k) = data.frame;
            k = k + 1;
        end
    end
end