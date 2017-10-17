function lutOut = genJFILbiltIRValueAdaptR()

% depth difference range depending on depth
% 6bit -> 8bit

% map depth different to sigmoid
minImpactRange = 30; % in DN at 0 values
maxImpactRange = 240; % in DN at max DN
x = 0:63; % full range of central pixel

impactRange = (tanh((x-32)/24)+1)*(maxImpactRange-minImpactRange)/2+minImpactRange;
%figure; plot(x, impactRange);

% LUT is range (0..255) + 4 extra bit precision div by mm
LUT = uint8(round((2^(8+4))./impactRange));
%figure; plot(x, LUT)

%figure; plot(LUT);

% f = fopen('../JFILbiltIRValueAdaptR.lut', 'wt');
% fprintf(f,'%02x\n', LUT);
% fclose(f);

lutOut.lut = LUT;
lutOut.name = 'JFILbiltIRValueAdaptR';
end