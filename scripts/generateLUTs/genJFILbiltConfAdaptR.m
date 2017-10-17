function lutOut = genJFILbiltConfAdaptR()

% conf:4bit -> sharpness:6bit

% sharpness : 0..63, default 16 is nominal sharpness

confFit = [6 7 8 9 10 12];
sharpFit = [2 4 6 9 12 24];

rdPolyFit = polyfit(confFit, sharpFit, 2);
LUT = uint8(floor(polyval(rdPolyFit, 0:15)));
LUT(1:6) = 1; % for conf 0:5
LUT = min(LUT, 63); % clipping is just in case

%figure; plot(LUT);

%f = fopen('../JFILbiltConfAdaptR.lut', 'wt');
%fprintf(f,'%02x\n', LUT);
%fclose(f);


lutOut.lut = LUT;
lutOut.name = 'JFILbiltConfAdaptR';
end