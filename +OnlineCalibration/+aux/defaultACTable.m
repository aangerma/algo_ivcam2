function [acTable] = defaultACTable()
acTable.timestamp =  0;
acTable.acVersion = 0;
acTable.flags =  1;
acTable.hFactor = 1;
acTable.vFactor = 1;
acTable.hOffset = 0;
acTable.vOffset =  0;
acTable.rtdOffset = 0;
acTable.reserved = zeros(12,1,'uint8');
end

