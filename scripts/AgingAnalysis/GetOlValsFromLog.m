function [driveVals, fovVals, hum] = GetOlValsFromLog(fileName)
    
    driveVals = NaN;
    fovVals = NaN;
    hum = NaN;
    en = false;
    
    fid = fopen(fileName, 'rt');
    while true
        ln = fgetl(fid);
        if (ln==-1)
            break
        end
        ind = strfind(ln, 'Humidity temperature is:');
        if ~isempty(ind)
            hum = sscanf(ln(ind:end), 'Humidity temperature is: %f');
        end
        en = en || contains(ln, 'Enable FA OL');
        en = en && ~contains(ln, 'Enable SA OL');
        if en
            ind = strfind(ln, 'Write value: ');
            if ~isempty(ind)
                lastDrive = sscanf(ln(ind:end), 'Write value: %f');
            end
            ind = strfind(ln, 'Finish Calc FOV - size:');
            if ~isempty(ind)
                lastFov = sscanf(ln(ind:end), 'Finish Calc FOV - size:%f');
                driveVals(end+1,1) = lastDrive;
                fovVals(end+1,1) = lastFov;
            end
        end
    end
    fclose(fid);
    
end