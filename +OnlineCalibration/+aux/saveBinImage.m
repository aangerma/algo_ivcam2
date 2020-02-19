function saveBinImage(folder,fname,img,type)
    
mkdirSafe(folder);

for i = 1:size(img,3)
    im2save = img(:,:,i);
    fullname = fullfile(folder,[fname,'_',type,sprintf('_%02d',i-1),'.bin']);

    f = fopen(fullname,'w');
    fwrite(f,(vec(im2save')),type);
    fclose(f);

end

end