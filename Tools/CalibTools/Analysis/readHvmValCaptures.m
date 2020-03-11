function [captures,distance,zRes,rgbRes] = readHvmValCaptures(testDir)
    %readHvmValCaptures read all the capures from a IQ val folder and parse
    %it correctly according to the file type.
    captures = [];
    files = dirFiles(testDir,'I*.bin',0);
    
    %get the z resolution and distance from the file name
    parts = strsplit(files{1},'_');
    distance = str2double(parts{2});
    zRes = str2double(strsplit(parts{3},'x'));
    
    %read I images
    files = dirFiles(testDir,'I*.bin',1);
    captures.I = cellfun(@(x)(du.formats.readBinFile(x,zRes,8)),files,'uni',false);
    
    %read Z images
    files = dirFiles(testDir,'Z*.bin',1);
    captures.D = cellfun(@(x)(du.formats.readBinFile(x,zRes,16)),files,'uni',false);
    
    %read Vertices
    files = dirFiles(testDir,'Vertices*.bin',1);
    [captures.X,captures.Y,captures.Z] = cellfun(@(x)(du.formats.readVerticesBinFile(x,zRes)),files,'uni',false);
    
    %get the rgb resolution from the file name
    files = dirFiles(testDir,'YUY2*.bin',0);
    parts = strsplit(files{1},'_');
    rgbRes = str2double(strsplit(parts{3},'x'));
    
    files = dirFiles(testDir,'YUY2*.bin',1);
    captures.RGB = cellfun(@(x)(du.formats.readBinRGBImage(x,rgbRes,5)),files,'uni',false);
    
    %read UV
    files = dirFiles(testDir,'UV*.bin',1);
    [captures.U,captures.V] = cellfun(@(x)(du.formats.readUVBinFile(x,zRes)),files,'uni',false);
    
    %mapped RGB
    captures.WarpedRGB =  cellfun(@(r,u,v)(du.math.imageWarp(double(r), v*rgbRes(2), u*rgbRes(1))),captures.RGB,captures.U,captures.V,'uni',false);
end