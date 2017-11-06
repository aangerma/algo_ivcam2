function out_dir = dirRecursive(in_dir,mask)
%REC_DIR recursivly goes over ona specified directory
%   goes over on all subdirectories in in_dir, and concatenate the result
%   to the cell array out_dir. only directories containing files specified
%   in mas will be added to the list
% example: rec_dir('c:\','*.bat');
% this example will return a cell array containing all .bat files in c:
if(~exist('mask','var'))
    mask='*.*';
end
os = getenv('OS');
if(strcmpi(os,'linux'))
      cmd = sprintf('find %s -name "%s"',in_dir,mask);
else
    cmd = sprintf('dir /S/B %s%s%s',in_dir,filesep,mask);
end
[temp str]=system(cmd); %#ok


res=regexp(str,[strrep(strrep(in_dir,'\','\\'),'+','\+') '([^\n]+)\n'] ,'tokens');
if(isempty(res))
    out_dir=[];
else
    out_dir = strcat(in_dir,[res{:}]');
end

end