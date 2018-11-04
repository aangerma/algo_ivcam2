function readAndShow(fb)
% type = 'uint32';
% f = fopen(fb,'rb');
% buffer = fread(f,Inf,type);
% fclose(f);
% buffer = dec2hex(buffer);
% Z = hex2dec(buffer(:,4:7));
% I = hex2dec(buffer(:,1:2));
% figure;
% tabplot; 
% plot(Z/8);
% title('Z');
% tabplot; 
% plot(I);
% title('IR');

fileID = fopen(fb,'r');
formatSpec = 'address: A00E05F4 value: %x\n';
buffer = dec2hex(fscanf(fileID,formatSpec));
Z = hex2dec(buffer(:,4:7));
I = hex2dec(buffer(:,1:2));
C = hex2dec(buffer(:,3));
fclose(fileID);
figure;
tabplot; 
plot(Z/8);
title('Z');
tabplot; 
plot(I);
title('IR');
tabplot; 
plot(C);
title('C');

