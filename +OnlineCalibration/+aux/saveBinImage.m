function saveBinImage(folder,fname,img,type)
if ~OnlineCalibration.Globals.saveBinsFlag
    return;
end

mkdirSafe(folder);
sz = size(img(:,:,1));
resStr = sprintf('%dx%d',sz);
for i = 1:size(img,3)
    im2save = img(:,:,i);
    fullname = fullfile(folder,[fname,'_',resStr,'_',type,sprintf('_%02d',i-1),'.bin']);

    f = fopen(fullname,'w');
    fwrite(f,(vec(im2save')),type);
    fclose(f);

end

end