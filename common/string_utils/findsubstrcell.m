function ind = findsubstrcell(cellArrayData, subStr)
%  IND =FINDSUBSTRCELL(CELLARRAYDATA, SUBSTR) 
%  FINDSUBSTRCELL Returens the indices of the cells in a string cell array 
%       that contain a given sub string input
% 
% Example:
%   cellData = {'aa', 'bb', 'ba' , 'ab', 'cb' ,'cab'}
%   indA = findsubstrcell(cellData,'a')
%   cellData(indA)
%
%   ans = 
% 
%       'aa'    'ba'    'ab'    'cab'

% Saki 03/08

ind = cellfun(@(x) ~isempty(strfind(x,subStr)),cellArrayData);