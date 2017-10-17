function lutOut =  genJFILbiltConfAdaptS()

% conf:4bit -> sharpness:5bit

% sharpness : 0..31, default 8 is nominal sharpness

confFit = [6 7 8 9 10 12];
sharpFit = [1 2 3 5 5 12];

rdPolyFit = polyfit(confFit, sharpFit, 2);
LUT = uint8(floor(polyval(rdPolyFit, 0:15)));
LUT(1:6) = 1; % for conf 0:5
LUT = min(LUT, 31);


%     figure; plot(LUT);

% f = fopen('../JFILbiltConfAdaptS.lut', 'wt');
% fprintf(f,'%02x\n', LUT);
% fclose(f);

lutOut.lut = LUT;
lutOut.name = 'JFILbiltConfAdaptS';
end