%%%%%%%%%
restoredefaultpath;
addpath(cd);
p=strsplit(genpath(fullfile(cd,filesep,'common')),';');
ishidden=cellfun(@(x) ~isempty(regexp(x,'\\\.[^\.]', 'once')),p);
addpath(strjoin(p(~ishidden),';'));
clear p ishidden RESTOREDEFAULTPATH_EXECUTED;