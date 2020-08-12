function saveFigureAsImage(f,runParams,block,name,addNumericPostFix,saveAsFig,closeFigure)
if ~exist('closeFigure','var')
    closeFigure = 1;
end
if ~exist('saveAsFig','var')
    saveAsFig = 0;
end
if saveAsFig
   pfix = '.fig'; 
else
   pfix = '.png';
end
if ~exist('addNumericPostFix','var')
    addNumericPostFix = 0;
end
if isempty(runParams) || ~isfield(runParams, 'outputFolder')
    close(f);
    return
end

imDir = fullfile(runParams.outputFolder,'figures');
mkdirSafe(imDir);
if addNumericPostFix
    i = 0;
    maxFigures = 200;
    impath = fullfile(imDir,strcat(block,'_',name,sprintf('_%02d',i),pfix));
    while (exist(impath, 'file') == 2) && i < maxFigures
       i = i + 1;
       impath = fullfile(imDir,strcat(block,'_',name,sprintf('_%02d',i),pfix));
    end
else
    impath = fullfile(imDir,strcat(block,'_',name,pfix));
end


set(0, 'currentfigure', f);
if ~saveAsFig
    saveas(f,impath)
elseif f.isvalid
    savefig(f,impath);
end
if closeFigure
    close(f);
end

end