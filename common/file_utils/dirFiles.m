function fn = dirFiles(baseLib,mask,fullpath)
    if(~exist('mask','var'))
        mask = '*.*';
    end
    if(baseLib(end)~=filesep)
        baseLib(end+1)=filesep;
    end
    fn = dir([baseLib,mask]);
    fn = {fn(~[fn.isdir]).name}';
    if((exist('fullpath','var') && fullpath==false))
    else
        fn = strcat(baseLib ,fn);
    end
    
end