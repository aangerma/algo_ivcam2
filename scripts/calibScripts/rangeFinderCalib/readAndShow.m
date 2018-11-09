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
padd = repmat('0',size(buffer,1),8-size(buffer,2));
buffer = [padd,buffer];
Z = hex2dec(buffer(:,5:6));
I = hex2dec(buffer(:,2:3));
C = hex2dec(buffer(:,4));
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

