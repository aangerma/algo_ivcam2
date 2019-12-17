function [Ttot,tableLength] = getTableTotTime(tableData,ixStart,ixEnd)
Ttot = sum(tableData(ixStart:ixEnd));
tableLength = numel(tableData(ixStart:ixEnd));
end

