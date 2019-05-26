function im = GetFramesFromDir(path,width, hight,type)
    if(~exist('type','var'))
        type = 'I';
    end
    if (type =='Z')
        files = dirFiles(path,'Z*.bin');
        n = length(files);
        im = uint16(zeros(hight,width,n));
        for i=1:n
            im(:,:,i) = reshape(typecast(readAllBytes(cell2str(files(i))),'uint16'),hight,width); 
        end
    else % no type default I
        files = dirFiles(path,'I*.bin');
        n = length(files);
        im = uint8(zeros(hight,width,n));
        for i=1:n
            im(:,:,i) = reshape(readAllBytes(cell2str(files(i))),hight,width); 
        end
    end

end