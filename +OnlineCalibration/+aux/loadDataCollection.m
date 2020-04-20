
dirPath = 'X:\IVCAM2_calibration _testing\19.2.20\F9440687\Snapshots\LongRange 480X640 (RGB 640X360)';
dirInfo = dir(dirPath);
figure;
for k = 1:numel(dirInfo)
    if dirInfo(k).isdir
        continue;
    end
    if contains(dirInfo(k).name, 'I_GrayScale')
        splittedStr = strsplit(dirInfo(k).name,'_');
        splittedStr = strsplit(splittedStr{3},'x');
        [ Iim ] = io.readGeneralBin( fullfile(dirPath,dirInfo(k).name),'uint8',[str2double(splittedStr{2}),str2double(splittedStr{1})] );
        subplot(311); imagesc(Iim); impixelinfo; title('IR image');colorbar;
    end
    if contains(dirInfo(k).name, 'Z_GrayScale')
        splittedStr = strsplit(dirInfo(k).name,'_');
        splittedStr = strsplit(splittedStr{3},'x');
        [ Zim ] = io.readGeneralBin( fullfile(dirPath,dirInfo(k).name),'uint16',[str2double(splittedStr{2}),str2double(splittedStr{1})] );
        subplot(312);imagesc(Zim./4); impixelinfo; title('Depth image');colorbar;
    end
    
    if contains(dirInfo(k).name, 'YUY2')
        splittedStr = strsplit(dirInfo(k).name,'_');
        splittedStr = strsplit(splittedStr{3},'x');
        rgbIm = du.formats.readBinRGBImage(fullfile(dirPath,dirInfo(k).name),[str2double(splittedStr{1}),str2double(splittedStr{2})] ,5);
        subplot(313);imagesc(rgbIm); impixelinfo; title('Color image');colorbar;
    end
end
