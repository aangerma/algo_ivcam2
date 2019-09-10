function [horzTilt, vertTilt] = readTiltsFromUnit(hw)

saTiltText = hw.cmd('ERB 0x4a0 2');
saTiltHex = saTiltText([end-1:end, end-4:end-3]);
saTilt = typecast(uint16(hex2dec(saTiltHex)),'int16'); % [mdeg]
horzTilt = single(saTilt)/1e3; % [deg]

faTiltText = hw.cmd('ERB 0x49e 2');
faTiltHex = faTiltText([end-1:end, end-4:end-3]);
faTilt = typecast(uint16(hex2dec(faTiltHex)),'int16'); % [mdeg]
vertTilt = single(faTilt)/1e3; % [deg]

