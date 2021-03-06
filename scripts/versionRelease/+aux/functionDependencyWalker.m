function funcs = functionDependencyWalker(fn,warnExternalToolboxes)
if(~exist('warnExternalToolboxes','var'))
    warnExternalToolboxes=false;
end
funcs ={};
recursionDepth=0;
funcs = getFuncRec(fn,funcs,recursionDepth,warnExternalToolboxes);
funcs=funcs';
end



function funcsAcc = getFuncRec(fn,funcsAcc,recusionDepth,warnExternalToolboxes)
if(recusionDepth==1e2)
    error('too many recursion??(%s',fn);
end

if(sum(strcmpi(funcsAcc,fn))~=0)
    return;
    
end
funcsAcc{end+1} =(fn);
funcs=getDepndentFuncs(fn,warnExternalToolboxes);


for i=1:length(funcs)
    funcsAcc = getFuncRec(funcs{i},funcsAcc,recusionDepth+1,warnExternalToolboxes);
    
end



end


function funcs=getDepndentFuncs(fn,warnExternalToolboxes)
[~,~,ext]=fileparts(fn);
switch(ext)
    case '.m'
        funcs = mfileFuncs(fn,warnExternalToolboxes);
    case {'.mexw64','.mexa64'}
        funcs = mexfileFuncs(fn);
    otherwise
        funcs={};
end
funcs=funcs(~strcmpi(funcs,fn));
end
function funcs = mexfileFuncs(fn)
[bsdr,purefn]=fileparts(fn);
funcs{1} = fn;
%add cpp source
if(exist(fullfile(bsdr,[purefn '.cpp']),'file'))
    funcs{2} = fullfile(bsdr,[purefn '.cpp']);
elseif(exist(fullfile(bsdr,[purefn 'src']),'dir'))
    funcs = [funcs;dirRecursive(fullfile(bsdr,[purefn 'src']))];
else
    error('could not find %s source',fn);
end
end
function funcs = mfileFuncs(fn,warnExternalToolboxes)
funcs={};
txt = fileread(fn);
txt = strrep(txt,'\','');
%remove first line
txt = txt(find(txt==char(10),1):end);

%remove text
txt=removeTokens(txt,'''([^''\n]*)''');
%remove comments 1
txt=removeTokens(txt,'%{.+?(?=%})');
%remove comments 2
txt=removeTokens(txt,'%[^\n]+\n');

r=regexp(txt,'[\*\s\+\-\\\/\=\(\[]*(?<func>[\.a-zA-Z0-9_]+)\s*\(','tokens');r = [r{:}];
%catch function refrences
r2=regexp(txt,'\@(?<func>[\.a-zA-Z0-9_]+)','tokens');r2=[r2{:}];
r = unique([r r2]);
for i=1:length(r)
    fnps = which(r{i});
    if(isempty(fnps))
        continue;
    end
    if(strcmpi(fnps,'variable'))
        continue;
    end
    if(~isempty(strfind(fnps,'built-in')))
        continue;
    end
    
    if(~isempty(strfind(fnps,matlabroot)))
        
        toolboxName = regexp(fnps,'toolbox\\([^\\]+)','tokens');toolboxName =toolboxName{1}{1};
        if(warnExternalToolboxes && ~strcmpi(toolboxName,{'matlab','shared'}))
            warning('Using  %s toolbox in file %s (func %s)',toolboxName,fn,r{i});
        end
        
        continue;
    end
    
    if(~isempty(strfind(fnps,'Java method')))
        continue;
    end
    if(isequal(fn,fnps))
        continue;
    end
    funcs{end+1}=fnps;%#ok
    
end
funcs=funcs';

end

function txt=removeTokens(txt,token)
% [begi,endi]=regexp(txt,token);
% for i=length(begi):-1:1
%     txt(begi(i):endi(i))=[];
% end
txt=regexprep(txt,token,'');
end
