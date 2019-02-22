function [frames,coolingStage] = loadDataSet(dataSetDir)


%% Plot temperature over time graph
iteration = dir(dataSetDir);
iteration = iteration(3:end);
k = 1;
for i = 1:numel(iteration)
    subdir = fullfile(dataSetDir,iteration(i).name);
    if contains(iteration(i).name,'iter')
        [frames{k},coolingStage(k).data] = loadDataSetDir(subdir);
        k = k+1;
    end
        
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