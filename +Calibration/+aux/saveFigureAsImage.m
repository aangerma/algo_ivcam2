function saveFigureAsImage(f,runParams,block,name)
if isempty(runParams)
    close(f);
    return
end

imDir = fullfile(runParams.outputFolder,'figures');
mkdirSafe(imDir);
impath = fullfile(imDir,strcat(block,'_',name,'.png'));

set(0, 'currentfigure', f);
saveas(f,impath)
close(f);
end