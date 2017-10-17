function lutOut = genJFILbiltConfWeight()

% conf:4bit -> weight:5bit

% sharpness : 0..63, default 16 is nominal sharpness

lutSigmoid = floor((tanh(((0:15)-7)/2.5)+1)*16);

LUT = uint8(max(lutSigmoid,1)); % no zero values

%figure; plot(LUT);

% f = fopen('../JFILbiltConfWeightD.lut', 'wt');
% fprintf(f,'%02x\n', LUT);
% fclose(f);
% 
% f = fopen('../JFILbiltConfWeightIR.lut', 'wt');
% fprintf(f,'%02x\n', LUT);
% fclose(f);

lutOut1.lut = LUT;
lutOut1.name = 'JFILbiltConfWeightD';
lutOut2.lut = LUT;
lutOut2.name = 'JFILbiltConfWeightIR';
lutOut = [lutOut1,lutOut2];
end