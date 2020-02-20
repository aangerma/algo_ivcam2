function im = GetFramesFromDir(path,width, height,type)
    if(~exist('type','var'))
        type = 'I';
    end
    if strcmp(type, 'Z')
        files = dirFiles(path,'Z*.bin');
        n = length(files);
        im = uint16(zeros(height,width,n));
        for i=1:n
            im(:,:,i) = reshape(typecast(readAllBytes(cell2str(files(i))),'uint16'),height,width); 
        end
    elseif strcmp(type, 'I')
        files = dirFiles(path,'I*.bin');
        n = length(files);
        im = uint8(zeros(height,width,n));
        for i=1:n
            im(:,:,i) = reshape(readAllBytes(cell2str(files(i))),height,width); 
        end
    elseif strcmp(type, 'YUY2')
        files = dirFiles(path,'YUY2*.bin');
        n = length(files);
        im = uint8(zeros(height,width,n));
        for i=1:n
            fprintf('%d\n',i);
            im(:,:,i) = du.formats.readBinRGBImage(cell2str(files(i)), [width height], 5);
        end
    end

end