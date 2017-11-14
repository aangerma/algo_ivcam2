% function str = struct2string(s,equal_sign,delimiter)
% O.Menashe 4/2013
% Transform struct to string that is a list of field=value (the delimiter and equal sign can be controlled).
function str = struct2str(s,equal_sign,delimiter,tab)
if ~exist('equal_sign','var')
    equal_sign = ':';
end
if ~exist('delimiter','var')
    delimiter = '\n';
end
if ~exist('tab','var')
    tab = '\t';
end

fn = fieldnames(s);
c=struct2cell(s);
oknum2str = cellfun(@(x) isnumeric(x) || ischar(x) || islogical(x),c);
c(oknum2str) =cellfun(@(x) num2str(x),c(oknum2str),'uni',false);

okstruct2str = cellfun(@(x) isstruct(x),c);
c(okstruct2str) =cellfun(@(x) [delimiter tab tab struct2str(x,equal_sign,[delimiter '\t'],tab)],c(okstruct2str),'uni',false);


c(~oknum2str & ~okstruct2str )=cellfun(@(x) 'NaN',c(~oknum2str & ~okstruct2str ),'uni',false);

c = cellfun(@(x) x(:)',c,'uni',false);
c = strcat(equal_sign,  c,delimiter);
c=[fn c];
c=c';
c = [c{:}];
c(end-length(delimiter)+1:end)=[];
str=sprintf(c);

end
