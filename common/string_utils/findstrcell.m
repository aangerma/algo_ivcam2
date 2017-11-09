function [ind]=findstrcell(cellArrayData, name)
% Returens the indices of a string cell array equal to a given input name
% function [ind]=findstrcell(cellArrayData, name)

ind = find(strcmpi(cellArrayData, name));
