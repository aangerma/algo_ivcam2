function binFileName = genTableBinFileName(tableName, vers)

major = floor(vers);
minor = round(100*mod(vers,1));
binFileName = sprintf('%s_Ver_%02d_%02d.bin', tableName, major, minor);
if (major==0)
    warning('version is set to default value 0');
end



