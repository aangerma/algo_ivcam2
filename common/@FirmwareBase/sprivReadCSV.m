function v = sprivReadCSV(fn)
v = fileread(fn);
v=regexprep(v,'[ \t]*,[ \t]*',',');%kill lead and tail white space(csv)
v=regexprep(v,'[ \t]*\n','\n');%kill tail white space
v=regexprep(v,'\n[ \t]*','\n');%kill head white space

v=regexprep(v,'[ \t]*\r\n','\r\n');%kill tail at EOL
v=regexprep(v,'\n%[^\n]+','');%kill comments
% v=regexprep(v,'(?:\r\n){2,}','\r\n');%kill emptylines (?:\r\n) --> find sequence \r\n     {2,}-->than apears 2 times or more
v=regexprep(v,'\r','');%remove cartridge return
v=regexprep(v,'(?:\n){2,}','\n');



v=str2cell(v,10);
v(cellfun(@(x) length(x)<=1,v))=[];
v(cellfun(@(x) x(1)=='%',v))=[];
% v = v(cellfun(@(x) checkIfGoodRow(x),v));
v=cellfun(@(x) str2cell(x,',')',v,'uni',false);
% v=cellfun(@(x) strtrim(x),v,'uni',false);
if(~isempty(v))
    n = length(v{1});
else
    n = 0;
end
sameLenAsHeader = cellfun(@(x) length(x)==n,v);
if(~all(sameLenAsHeader))
    notSameLenAsHeader = find(~sameLenAsHeader,1);
    error('row %d in file %s: #cells is not consistent with #headers:\n%s',notSameLenAsHeader,fn,cell2str(v{notSameLenAsHeader},','));
end

% v=v(cellfun(@(y) ~all(cellfun(@(x) isempty(x),y)),v));
v=[v{:}]';

end
