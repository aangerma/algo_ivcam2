ir = nan(768,1024,30);
z = nan(768,1024,30);
for i = 0:29
    irfn = sprintf('X:\\Users\\tmund\\roifromZ2\\XGA_I_GrayScale_1024x768_00.00.00.0000_F9220056_00%02g.bin',i);
    zfn = sprintf('X:\\Users\\tmund\\roifromZ2\\XGA_Z_GrayScale_1024x768_00.00.00.0000_F9220056_00%02g.bin',i);

        
    ir(:,:,i+1) = io.readGeneralBin(irfn,'uint8',[768,1024]);
    z(:,:,i+1) = io.readGeneralBin(zfn,'uint16',[768,1024]);
end
zCopy = z;
zCopy(z==0) = nan;%randi(9000,size(zCopy(z==0)));
stdZ = nanstd(zCopy,[],3);
stdZ(isnan(stdZ)) = inf;
I = (stdZ<50) & (sum(~isnan(zCopy),3) == 30);
se = strel('disk',10);
dI = imclose(I,se);
figure,imagesc(I)
figure,imagesc(dI)