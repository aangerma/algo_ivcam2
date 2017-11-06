% function itemList = string2list(inputString,delimiters,alsoEmpty)
%
% Converts a string into a collection of strings according to given delimiters.
% Input:
% inputString - string to parse
% delimites - list of delimiters (string)
% alsoEmpty - if true, empty elements (i.e. 2 consecutive delimiters) are also returned, otherwise
%             empty elements are ignored (this mode is faster).
%
function itemList = string2list(inputString,delimiters,alsoEmpty)
        if ~exist('alsoEmpty','var')
                alsoEmpty = false;
        end;

        itemList = strread(inputString,'%s','delimiter',delimiters);
        if ~alsoEmpty
                goodIndexes = true(1,length(itemList));
                for i=1:length(itemList)
                        if (isempty(itemList{i}))
                                goodIndexes(i) = false;
                        end
                end
                goodIndexes = find(goodIndexes);
                N = length(goodIndexes);
                newItemList = cell(1,N);
                for i=1:N
                        newItemList{i} = itemList{goodIndexes(i)};
                end
                itemList = newItemList;
        end          
end





