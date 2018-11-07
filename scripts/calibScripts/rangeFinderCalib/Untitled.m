x = ['49 09 8F 07 19 01 1F 08 4D 06 DE 07 7A 0D EE 07 B7 00 5F 08 5E 0B AE 07 92 13 8E 07 7C 01 CE 07 99 09 5F 08 E2 09 BE 07 DB 0C 5F 08 DE 10 0F 08']
x = strsplit(x);

zic = zeros(numel(x),3);
for i = 1:numel(x)
   st = [x{i,1}, x{i,2}];
    zic(:,1) = 
    zic(:,1) = 
end


79 0F DE 07
2C 0D EE 07

'07DE0F79'
'07EE0D2C'

z = @(s) hex2dec(s(end-3:end));
z('07DE0F79')
z('07EE0D2C')
fb = 'C:\temp\gg.bin';

type = 'uint32';
f = fopen(fb,'rb');
buffer = fread(f,Inf,type);
fclose(f);
buffer = dec2hex(buffer);
Z = hex2dec(buffer(:,4:7));
plot(Z)


img = reshape(buffer,fliplr(imgSize))';