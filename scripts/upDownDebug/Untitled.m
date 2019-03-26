a = csvread("\\ger\ec\proj\ha\RSG\SA_3DCam\TMund\record\C3pass00000.dat");

A=importdata('\\ger\ec\proj\ha\RSG\SA_3DCam\TMund\record\C3pass00000.dat');

i0 = 515000;
i1 = 1475000;
iv = i0:i1;

t = A(iv,1);
v = A(iv,2);
tabplot;
plot(t,v);

dt = t(2)-t(1);

newDT = dt;
newT = t(1):newDT:t(end);
newV = interp1(t,v,newT);

for i = 20
nPeriod = round((3.984/4*64e-9)/newDT);
nPeriod = nPeriod+i;
nV = numel(newV);
scan = newV;
scan(end-mod(nV,nPeriod)+1:end) = [];
nScan = numel(scan);
scan = reshape(scan,nPeriod,nScan/nPeriod);
figure(1)
tabplot(i);plot(scan(:,[10:10:100]))
% figure(2);
% tabplot(i);
% plot(1:size(scan,1),double(scan(:,40)>0.04),'r',1:size(scan,1),double(scan(:,50)>0.04)*2,'b')
end


ref = double(scan(:,180));
scan = double(scan);
x = Utils.correlator(scan(1:end,1:end),ref(1:end));
x = circshift(x,1000,1);
tabplot;imagesc(x)
[~,am] = max(x);
tabplot;plot(am)

