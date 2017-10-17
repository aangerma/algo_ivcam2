function lutOut = genRASTdivCma()

% DivLUT
dvC = 1:256;
dvL = 255./dvC; % should be 256 but 255 is a good approximation
DivLUT = uint8(floor(dvL));
LUT = uint8([0 DivLUT(1:127)]);

%% DivLUT 7bit
dvC = 1:32;
dvL = 127./dvC; % should be 256 but 255 is a good approximation
DivLUT = uint8(round(dvL));
LUT = uint8([0 DivLUT(1:31)]);
ErrLUT = (127-min(127,(1:31).*double(LUT(2:32))))./127; % for debugging
figure; plot(ErrLUT);


%{
DivLUT = uint8(round(dvL));
LUT = uint8([0 DivLUT(1:127)]);
ErrLUT = (255-min(255,(1:31).*double(LUT(2:32))))./255; % for debugging
figure; plot(ErrLUT);
%}


%%
S = sprintf('%03u;%03u;%03u;%03u\n', fliplr(reshape(LUT,4,[])')');

h = sprintf('%02X%02X%02X%02X', fliplr(reshape(LUT,4,[])')');
H = reshape(h, 8, [])';
hex2dec(H)

%% DivLUT 6bit
%dvC = 1:64;
%dvL = 63./dvC; % should be 256 but 255 is a good approximation
%DivLUT = uint8(floor(dvL));
%ErrLUT = (63-double(DivLUT).*dvC)./63; % for debugging
%LUT = [0 DivLUT(1:63)];

%figure; plot(LUT);

% f = fopen('../RASTdivCma.lut', 'wt');
% fprintf(f,'%02x\n', LUT);
% fclose(f);

lutOut.lut = LUT;
lutOut.name = 'RASTdivCma';
end