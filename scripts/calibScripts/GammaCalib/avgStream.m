function pgAvg = avgStream(dirName,prefix,suffix,N)
%AVGSTREAM average N images from dir dirName that starts with prefix and
%end with suffix.

imPath = fullfile(dirName,[prefix sprintf('%04d',0) suffix]);
I = readGrayImage(imPath);
d = zeros([size(I),N],'uint8');
d(:,:,1) = I;

for i = 1:N-1
    imPath = fullfile(dirName,[prefix sprintf('%04d',i) suffix]);
    d(:,:,i+1) = readGrayImage(imPath);
end
pgAvg = mean(d,3);

