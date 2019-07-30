function [ img ] = readGeneralBin( fname,type,imgSize )
%READBINFROMIPDEV read a binary image file with the given type and reshapes
%it to the desired image size.


f = fopen(fname,'rb');
buffer = fread(f,Inf,type);
fclose(f);

img = reshape(buffer(1:prod(imgSize)),fliplr(imgSize))';
end

