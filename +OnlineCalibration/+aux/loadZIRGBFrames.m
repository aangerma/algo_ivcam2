function frames = loadZIRGBFrames(dirname)
    Ifiles = dir(fullfile(dirname,'I_*'));
    splittedStr = strsplit(Ifiles(1).name,'_');
    splittedStr = strsplit(splittedStr{3},'x');
    for i = 1:numel(Ifiles)
       frames.i(:,:,i) = io.readGeneralBin(fullfile(Ifiles(i).folder,Ifiles(i).name),'uint8',[str2double(splittedStr{2}),str2double(splittedStr{1})]); 
    end
    Zfiles = dir(fullfile(dirname,'Z_*'));
    splittedStr = strsplit(Zfiles(1).name,'_');
    splittedStr = strsplit(splittedStr{3},'x');
    for i = 1:numel(Zfiles)
       frames.z(:,:,i) = io.readGeneralBin(fullfile(Zfiles(i).folder,Zfiles(i).name),'uint16',[str2double(splittedStr{2}),str2double(splittedStr{1})]); 
    end
    yuy2files = dir(fullfile(dirname,'YUY2_YUY2_*'));
    splittedStr = strsplit(yuy2files(1).name,'_');
    splittedStr = strsplit(splittedStr{3},'x');
    for i = 1:numel(yuy2files)
       [frames.yuy2(:,:,i),~] = du.formats.readBinRGBImage(fullfile(yuy2files(i).folder,yuy2files(i).name),[str2double(splittedStr{1}),str2double(splittedStr{2})],5);
    end
    
end