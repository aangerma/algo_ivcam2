
function frames = loadFrames(dirname)
    Ifiles = dir(fullfile(dirname,'I_*'));
    for i = 1:numel(Ifiles)
       frames.i(:,:,i) = io.readGeneralBin(fullfile(Ifiles(i).folder,Ifiles(i).name),'uint8',[480,640]); 
    end
    Zfiles = dir(fullfile(dirname,'Z_*'));
    for i = 1:numel(Zfiles)
       frames.z(:,:,i) = io.readGeneralBin(fullfile(Zfiles(i).folder,Zfiles(i).name),'uint16',[480,640]); 
    end
    yuy2files = dir(fullfile(dirname,'YUY2_YUY2_*'));
    for i = 1:numel(yuy2files)
       [frames.yuy2(:,:,i),~] = du.formats.readBinRGBImage(fullfile(yuy2files(i).folder,yuy2files(i).name),[1920,1080],5);
    end
    
end