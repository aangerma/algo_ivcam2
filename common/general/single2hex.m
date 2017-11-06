function [ hexArr ] = single2hex( singleArr )
    %HEX2SINGLE converts array of singles to cell array of hexadecimal strings
    func = @(x)(dec2hex(typecast(single(x),'uint32'),8));
    singleArr = num2cell(singleArr);
    hexArr = cellfun(func,singleArr,'uni',0);
end

