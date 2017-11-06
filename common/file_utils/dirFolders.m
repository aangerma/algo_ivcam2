function fn = dirFolders(baseLib,mask,fullpath)
    
    % input validation
    if ~exist('mask','var')
        mask = '*';
    end
    
    if ~exist('fullpath','var')
        fullpath = false;
    end
    
    % get directories
    fn = dir(fullfile(baseLib,mask));
    fn = {fn([fn.isdir]).name}';
    
    % remove .,..
    idxToRemove = [];
    idxToRemove = [idxToRemove find(strcmp(fn,'.')) find(strcmp(fn,'..'))];
    fn(idxToRemove) = [];
    
    % concatenate base dir
    if fullpath
        fn = fullfile(baseLib ,fn);
    end
end