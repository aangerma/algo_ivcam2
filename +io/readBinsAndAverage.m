function [averageIm] = readBinsAndAverage(dirPath,fnamePattern, extention,Size,bpp)
    frames=[];
    filesPattern = fullfile(dirPath, sprintf('%s*.%s', fnamePattern, extention));
    files = dir(filesPattern);
    
    for i=1:length(files)
        im(:,:,i)=du.formats.readBinFile(fullfile(files(i).folder, files(i).name),Size,bpp); 
    end 
    
    averageIm=mean(im,3); 
end

