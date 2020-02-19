baseDir = '\\143.185.124.250\Tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-3082';
OutputFolder = 'D:\Data\LIDAR\L515\Algo 2 PRQ';
unitsData = {};
units = listModulesInFolderIV2(baseDir);
folds = dirFolders(baseDir,[],1);
%   find dirs
while ~isempty(folds)
    currDir = folds{end};
    folds = folds(1:end-1);
    units = listModulesInFolderIV2(currDir);
    if isempty(units)
        currFolds = dirFolders(currDir,[],1);
        folds = [folds;currFolds];
    else
        for i=1:length(units)
            unitsData(end+1,:) = {units{i},currDir};
        end
    end
end

[units,ua,ub] = unique(unitsData(:,1));
for i=1:length(units)
    outPath = fullfile(OutputFolder,units{i});
    mkdirSafe(outPath);
    idxs = find(ub==i);
    for j=1:length(idxs)
        testPath = unitsData{idxs(j),2};
        attributes = split(testPath(length(baseDir)+1:end),filesep);
        goodIdxs = cellfun(@(x)(~isempty(x)),attributes);
        attributes = attributes(goodIdxs);
        rev = du.analysis.findAllRevisions(fullfile(testPath,units{i}),'validationData.mat','TC');
        figureFolder = fullfile(testPath,units{i},rev{end},'figures');
        figs = dirFiles(figureFolder,'*.png',0);
        for fid=1:length(figs)
            outFile = [strjoin([figs{fid}(1:end-4),attributes(:)'],'_') '.png'];
            copyfile(fullfile(figureFolder,figs{fid}),fullfile(outPath,outFile),'f')
        end
    end
end

