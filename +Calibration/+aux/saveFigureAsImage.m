function saveFigureAsImage(f,runParams,block,name,addNumericPostFix)
if ~exist('addNumericPostFix','var')
    addNumericPostFix = 0;
end
if isempty(runParams)
    close(f);
    return
end

imDir = fullfile(runParams.outputFolder,'figures');
mkdirSafe(imDir);
if addNumericPostFix
    i = 0;
    maxFigures = 50;
    impath = fullfile(imDir,strcat(block,'_',name,sprintf('_%02d',i),'.png'));
    while (exist(impath, 'file') == 2) && i < maxFigures
       i = i + 1;
       impath = fullfile(imDir,strcat(block,'_',name,sprintf('_%02d',i),'.png'));
    end
else
    impath = fullfile(imDir,strcat(block,'_',name,'.png'));
end


set(0, 'currentfigure', f);
saveas(f,impath)
close(f);
end