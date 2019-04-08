function [frames,coolingStage] = loadDataSet(dataSetDir,ignoreFirstNDeg)
if ~exist('ignoreFirstFrames','var')
   ignoreFirstNDeg = 0; 
end

%% Plot temperature over time graph
iteration = dir(dataSetDir);
iteration = iteration(3:end);
k = 1;
for i = 1:numel(iteration)
    subdir = fullfile(dataSetDir,iteration(i).name);
    if contains(iteration(i).name,'iter_00')
        [frames{k},coolingStage(k).data] = loadDataSetDir(subdir,ignoreFirstNDeg);
        k = k+1;
    end
        
end

end

function [frames,coolingStage] = loadDataSetDir(subdir,ignoreFirstNDeg)
    coolingStage = [];
    fnames = dir(subdir);
    fnames = fnames(3:end);
    k = 1;
    firstLddTemp = 0;
    for i = (1):numel(fnames)
        fname = fullfile(subdir,fnames(i).name);
        if contains(fname,'coolingLog')
            data = load(fname);
            coolingStage = data.coolingTable;
        elseif contains(fnames(i).name,'frameData')
            data = load(fname);
            if firstLddTemp == 0
                firstLddTemp = data.frame.temp.ldd;
            end
            if data.frame.temp.ldd - firstLddTemp >= ignoreFirstNDeg
                frames(k) = data.frame;
                k = k + 1;
            end
        end
    end
end