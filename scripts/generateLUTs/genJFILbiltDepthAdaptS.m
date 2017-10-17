function lutOut = genJFILbiltDepthAdaptS()

% depth difference range depending on depth
% 8bit -> 5bit

% map depth different to sigmoid
minSharpness = 1; % in mm at 2m depth range
maxSharpness = 14; % in mm at min depth range
x = 0:255; % full range of central pixel

% rdImpactRange is in mm
depthSharpness = (1-tanh((x-32)/32))*(maxSharpness-minSharpness)/2+minSharpness;
% figure; plot(bitshift(x, 16-10-zMaxSubMMExp), depthSharpness);

LUT = uint8(round(depthSharpness));

%figure; plot(LUT);

% f = fopen('../JFILbiltDepthAdaptS.lut', 'wt');
% fprintf(f,'%02x\n', LUT);
% fclose(f);

lutOut.lut = LUT;
lutOut.name = 'JFILbiltDepthAdaptS';
end