function lutOut = genRASTbiltSpat()

% adjust spatial weight depending on IR
% 6bit -> 4bit

% map depth different to sigmoid
W0 = 33; % in 0..14 at 0 values
W1 = 10; % in 0..14 at max DN
x = 0:63; % full range of central pixel

ws = (tanh((x-16)/24)+1)*(W1-W0)/2+W0;

LUT = uint8(round(ws));
LUT(64) = 0; % allow no smoothing
%figure; plot([ws' double(LUT)']);

% print to registers
% fprintf('%02X%02X%02X%02X\n', fliplr(reshape(LUT,4,[])')')

% f = fopen('../RASTbiltSpat.lut', 'wt');
% fprintf(f,'%01x\n', LUT);
% fclose(f);

lutOut.lut = LUT;
lutOut.name = 'RASTbiltSpat';
end