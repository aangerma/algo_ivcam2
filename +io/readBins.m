function frames = readBins(dirPath, fnamePattern, extention, varargin)
    frames=[];
    filesPattern = fullfile(dirPath, sprintf('%s*.%s', fnamePattern, extention));
    files = dir(filesPattern);

    for i = 1:length(files)
        frames(i).o = io.readBin(fullfile(files(i).folder, files(i).name));
    end
    
end