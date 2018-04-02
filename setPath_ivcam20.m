function  setPath_ivcam20()
restoredefaultpath;
addpath(cd);
p=strsplit(genpath(fullfile(cd,filesep,'common')),';');
ishidden=cellfun(@(x) ~isempty(regexp(x,'\\\.[^\.]', 'once')),p);
addpath(strjoin(p(~ishidden),';'));


%close open documents that are not part of the current path
X = matlab.desktop.editor.getAll;
X={X(cellfun(@(x) ~startsWith(x,cd),{X.Filename})).Filename};
for x=X(:)'
   matlab.desktop.editor.findOpenDocument(x{1}).close();
end
end
