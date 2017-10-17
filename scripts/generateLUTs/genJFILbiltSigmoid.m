function lutOut = genJFILbiltSigmoid()

% sigmoid for radiometric weights
% 6bit -> 8bit

lutSigmoid = floor((-tanh(((0:63)-32)/11)+1)*128);
lutSigmoid(64) = 0; % make sure the last element is 0

LUT = uint8(lutSigmoid);

%figure; plot(LUT);

% f = fopen('../JFILbiltSigmoid.lut', 'wt');
% fprintf(f,'%02x\n', LUT);
% fclose(f);

lutOut.lut = LUT;
lutOut.name = 'JFILbiltSigmoid';
end