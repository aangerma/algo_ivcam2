%str2cell
%converts a  string to  cell array 
%syntax: strout=str2cell(strin, delimeter)
%delimeter is the ceperator between the cellArray cells(default is ' ')
% 
%See also: cell2str
function outcell=str2cell(strin, Delimiter)
 if(~exist('Delimiter','var'))
        Delimiter=' ';
 end
del_locs=strfind(strin,Delimiter);
%if no delimiter was found
if(isempty(del_locs))
    outcell={strin};
    return;
end
del_locs=[1-+length(Delimiter) del_locs length(strin)+1];

outcell={};
for i=1:length(del_locs)-1
    outcell{i}=strin((del_locs(i)+length(Delimiter)):del_locs(i+1)-1);
end
% outcell=textscan(strin,'%s','Delimiter',Delimiter);
% outcell=outcell{1};

end