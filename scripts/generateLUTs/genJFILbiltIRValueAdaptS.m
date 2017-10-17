function lutOut = genJFILbiltIRValueAdaptS()

% depth difference range depending on depth
% 6bit -> 5bit

% map ir values to sigmoid
sharpness0 = 0; % at min IR values
sharpness1 = 10; % in mm at min depth range
x = 0:63; % full range of central pixel

% rdImpactRange is in mm
sharpness = ((tanh((x-32)/14))+1)*(sharpness1-sharpness0)/2+sharpness0;
% figure; plot(x, sharpness);

LUT = uint8(round(sharpness));

% figure; plot(LUT);

% f = fopen('../JFILbiltIRValueAdaptS.lut', 'wt');
% fprintf(f,'%02x\n', LUT);
% fclose(f);

lutOut.lut = LUT;
lutOut.name = 'JFILbiltIRValueAdaptS';
end