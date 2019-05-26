function  setPath_ivcam20(commonRoot)
    % add algo_ivcam2 path
    restoredefaultpath;
    addpath(cd);
    p=strsplit(genpath(fullfile(cd,filesep,'common')),';');
    ishidden=cellfun(@(x) ~isempty(regexp(x,'\\\.[^\.]', 'once')),p);
    addpath(strjoin(p(~ishidden),';'));

    % add algo_common to path
    ivcamRoot = fileparts(which(mfilename));
    if ~exist('commonRoot','var')
        commonRoot = fullfile(ivcamRoot,'..\algo_common');
    end
    
    if ~exist(commonRoot,'dir')
        error('Common Root was not found in %s',commonRoot);
    end
    cd(commonRoot);
    setPathCommon()
    
    cd (ivcamRoot);
    
    
    addpath(genpath(fullfile(ivcamRoot,'scripts','IV2calibTool')));
    addpath(genpath(fullfile(ivcamRoot,'scripts','IV2ThermalCalibTool')));
    addpath(genpath(fullfile(ivcamRoot,'CompiledAPI'))); % added path for compiled API (HVM tester functions);
    %close open documents that are not part of the current path
    X = matlab.desktop.editor.getAll;
    X={X(cellfun(@(x) ~startsWith(x,cd),{X.Filename})).Filename};
    for x=X(:)'
       matlab.desktop.editor.findOpenDocument(x{1}).close();
    end
end
