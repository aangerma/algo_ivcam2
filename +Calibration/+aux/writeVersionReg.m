function [] = writeVersionReg(filename, version, shortFirmwareFormat)
            
if ~exist('shortFirmwareFormat','var')
    shortFirmwareFormat = false;
end

if (shortFirmwareFormat)
    strVerReg = 'mwd a0020bd8 %08x // RegsDIGGspare_000\n';
else
    strVerReg = 'mwd a0020bd8 a0020bdc %08x // RegsDIGGspare_000\n';
end

[fileID, err] = fopen(filename, 'wt');
if ~isempty(err)
    error([filename ': ' err]);
end

fprintf(fileID, strVerReg, version);

fclose(fileID);


end

