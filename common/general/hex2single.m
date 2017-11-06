function [ singleArr ] = hex2single( hexArr )
    %HEX2SINGLE convert array\ cell array of hexadecimal strings to array
    %of singles
    func = @(x)(typecast(uint32(hex2dec(x)),'single'));
    if ~iscell(hexArr)
        hexArr = cellstr(hexArr);
    end
    singleArr = cell2mat(cellfun(func,hexArr,'uni',0));
end