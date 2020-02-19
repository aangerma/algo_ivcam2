function [params] = loadIPDevStatusFile(fname)


f = fopen(fname,'rb');
buffer = uint8(fread(f,512,'uint8'));
fclose(f);

addr = [0,4,12,32,36,40,44,48,84,128,132,136,172,192,208,256,292,304,336,340,344,348,352,356,360,364,368,372,412,416,420,424,428,432,436,476,480,484,512];
desc = {'Version','Module Serial Number','(Blank)','Depth Horizontal resolution','Depth Vertical resolution','Z scale','Z offset','K depth','(Blank)','RGB Horizontal resolution','RGB Vertical resolution','K RGB','RGB distortion','RGB temp transformation','(Blank)','RGB rotation','RGB translation','(Blank)','Sensetivity','APD offset','Laser Gain','Min Distance','Confidence','Sharpness','rastBilt','edge','invalidationBypass','(Blank)','LDD','Tsense','MA','HumidityT','HumidityH','MC','(Blank)','Spherical En','Jfil bypass','(Blank)',''};
format = {'uint32','int64','','float','float','float','float','3x3 float','','float','float','3x3 float','1x5 float','1x4 float','','3x3 float','3x1 float','','float','float','float','float','float','float','float','float','float','','float','float','float','float','float','float','','uint32','uint32','',''};
for i = 1:numel(desc)
    fieldName = desc{i};
    if i == numel(desc)
        value = buffer(addr(i)+1:end);
    else
        value = buffer(addr(i)+1:addr(i+1));        
    end
    form = format{i};
    if contains(form, 'uint32')
        finalValue = typecast(value,form);
    elseif contains(form, 'int64')
        finalValue = typecast(value,form);
    elseif contains(form, 'float')
        finalValue = typecast(value,'single');
    else
        continue;
    end
    newFieldName = strrep(fieldName,' ','_');
    params.(newFieldName) = finalValue;
    if numel(finalValue) == 9
        params.(newFieldName) = reshape(params.(newFieldName),3,3)';
    end
end

end

