function  setPath_ivcam20(commonRootIn,projID)
    % add algo_ivcam2 path
    restoredefaultpath;
    addpath(cd);
    p=strsplit(genpath(fullfile(cd,filesep,'common')),';');
    ishidden=cellfun(@(x) ~isempty(regexp(x,'\\\.[^\.]', 'once')),p);
    addpath(strjoin(p(~ishidden),';'));
    
    % add algo_common to path
    ivcamRoot = fileparts(which(mfilename));
    if ~exist('commonRootIn','var') || isempty(commonRootIn)
        commonRootIn = fullfile(ivcamRoot,'..\algo_common');
    end
    
    if ~exist(commonRootIn,'dir')
        error('Common Root was not found in %s',commonRootIn);
    end
    cd(commonRootIn);
    setPathCommon()
    
    cd (ivcamRoot);
    
    
    %addpath(genpath(fullfile(ivcamRoot,'scripts','IV2calibTool')));
    %addpath(genpath(fullfile(ivcamRoot,'scripts','IV2ThermalCalibTool')));
    addpath(genpath(fullfile(ivcamRoot,'Tools')));
    addpath(genpath(fullfile(ivcamRoot,'CompiledAPI'))); % added path for compiled API (HVM tester functions);
    addpath(genpath(fullfile(ivcamRoot,'CompiledAPI','Calc_Internal_Files'))); % added path for compiled API (HVM tester functions);
    %close open documents that are not part of the current path
    X = matlab.desktop.editor.getAll;
    X={X(cellfun(@(x) ~startsWith(x,cd),{X.Filename})).Filename};
    for x=X(:)'
        matlab.desktop.editor.findOpenDocument(x{1}).close();
    end
    
    global gProjID;
    if ~exist('projID','var')
        gProjID = iv2Proj.L515;
    else
        gProjID = iv2Proj(projID);
    end
end
