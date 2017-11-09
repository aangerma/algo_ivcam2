%cell2str
%converts a cell array to a string
%syntax: strout=cell2str(cellArr, delimeter)
%delimeter is the ceperator between the cellArray cells(default is ' ')
% 
%See also: str2cell
function strout=cell2str(cellArr, delimeter)
    if(~exist('delimeter','var'))
        delimeter=' ';
    end
    if(~iscell(cellArr))
        strout=cellArr;
        return;
    end
    strout='';
    for i=1:numel(cellArr)
        if(isfloat(cellArr{i}))
            strout=sprintf('%s%f%s',strout, cellArr{i},delimeter);
        elseif(isnumeric(cellArr{i}))
            strout=sprintf('%s%d%s',strout, cellArr{i},delimeter);
        else
            strout=sprintf('%s%s%s',strout, cellArr{i},delimeter);
        end
    end
    strout=strout(1:(end-length(delimeter)));
end