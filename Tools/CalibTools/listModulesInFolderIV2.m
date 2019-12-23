function [ list ] = listModulesInFolderIV2( baseDir)
    %LISTMODULESLISTINFOLDER Summary of this function goes here
    %   Detailed explanation goes here
    regexp = [];
    delimiter = '';
    if ~isempty(regexp)
        delimiter = '|';
    end
    regexp =[regexp delimiter '^[F][0-9]{7}$'];
    
    dirlist = dirFolders(baseDir);
    
    list = regexpi(dirlist,regexp,'match');
    list = [list{:}];
    
    
end

