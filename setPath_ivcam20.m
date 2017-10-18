restoredefaultpath;
addpath(cd);
p=strsplit(genpath(fullfile(cd,'..','AlgoCommon')),';');
ishidden=cellfun(@(x) ~isempty(regexp(x,'\\\.[^\.]', 'once')),p);
addpath(strjoin(p(~ishidden),';'));
clear;
