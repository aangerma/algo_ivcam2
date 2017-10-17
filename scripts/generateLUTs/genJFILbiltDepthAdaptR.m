function lutOut = genJFILbiltDepthAdaptR()

% zMaxSubMMExp = 3;

% depth difference range depending on depth
% 8bit -> 8bit

% map depth different to sigmoid
minImpactRange = 3.2; % in mm at 0 depth difference, min limit 2mm
maxImpactRange = 20; % in mm at 1/4 of depth different range
x = 0:255; % full range of central pixel

% rdImpactRange is in mm
impactRange = (tanh((x-128)/72)+1)*(maxImpactRange-minImpactRange)/2+minImpactRange;
%figure; plot(bitshift(x, 16-8-zMaxSubMMExp), impactRange);

% LUT is range (0..255) + 3 extra bit precision div by mm
LUT = uint8(round((2^(6+3))./impactRange));
%figure; plot(bitshift(x, 16-8-zMaxSubMMExp), LUT)

%figure; plot(LUT);

% f = fopen('../JFILbiltDepthAdaptR.lut', 'wt');
% fprintf(f,'%02x\n', LUT);
% fclose(f);

lutOut.lut = LUT;
lutOut.name = 'JFILbiltDepthAdaptR';
end