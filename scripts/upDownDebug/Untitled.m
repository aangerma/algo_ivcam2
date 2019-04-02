a = csvread("\\ger\ec\proj\ha\RSG\SA_3DCam\TMund\record\C3pass00000.dat");

A=importdata('\\ger\ec\proj\ha\RSG\SA_3DCam\TMund\record\C3pass00000.dat');
A=importdata('C:\Users\tmund\Desktop\C4pass00000.dat');
A = importdata('C:\Users\tmund\Desktop\PLL1G_CodeA_CH3 - Copy.dat');

i0 = 515000;
i1 = 1475000;

i0 = round(size(A,1)/8);

i1 = round(3*size(A,1)/8);
iv = i0:i1;

t = A(iv,1);
v = A(iv,2);
tabplot;
plot(t,v);

dt = t(2)-t(1);

newDT = dt/250;
newT = t(1):newDT:t(end);
newV = interp1(t,v,newT);

for i = 5152 %516*11
nPeriod = round((3.984/4*64e-9)/newDT);
nPeriod = nPeriod+i;
nV = numel(newV);
scan = newV;
scan(end-mod(nV,nPeriod)+1:end) = [];
nScan = numel(scan);
scan = reshape(scan,nPeriod,nScan/nPeriod);
% tabplot(i);plot(scan(:,[50,322]))
tabplot(i);plot(scan(:,[10,100]))
end


ref = double(scan(:,int32(end/2)));
scan = double(scan);
figure,imagesc(scan)

x = zeros(size(scan(1:10:end,1:10:end)));
for i = 1:size(x,2)
    fprintf('%d ',i);
    x(:,i) = Utils.correlator(scan(1:10:end,i*10),ref(1:10:end));
end
x = circshift(x,120000,1);
tabplot;imagesc(x)
[~,am] = max(x(1:2809,:));
tabplot;plot(am)
tabplot;plot(am*newDT)
tabplot;plot((1:numel(am))*10,am*newDT*10*(3*10^8)/2*1000)

fw = Pipe.loadFirmware('C:\Users\admin\Documents\workspace\algo_ivcam2\+Calibration\releaseConfigCalib');
txregs.FRMW.txCode = uint32([hex2dec('CFC3CFC0'),hex2dec('3F30C00C'),0,0]);
fw.setRegs(txregs,'');
regs = fw.get();
auxPItxCode = dec2hex(regs.EXTL.auxPItxCode);
auxPItxCode = [auxPItxCode(2,:),auxPItxCode(1,:)];
auxPItxCode = hexToBinaryVector(auxPItxCode,64);

newI = int32(floor(linspace(1,64.99999,nPeriod)));
refP = fliplr(double(auxPItxCode(newI)));
corr = (cconv(ref,fliplr(refP),nPeriod));
figure,plot(refP),hold on, plot(ref)
[~,am] = max(corr);
figure, 
plot(ref)
hold  on
plot(circshift(refP,(am-1)))

scan = double(scan);
x = zeros(size(scan(1:10:end,1:10:end)));
for i = 1:size(x,2)
    fprintf('%d ',i);
    x(:,i) = Utils.correlator(scan(1:10:end,i*10),ref(1:10:end));
end

% x = Utils.correlator(scan(1:end,1:end),refP(1:end)');
x = circshift(x,220000,1);
figure;
tabplot;imagesc(x)
[~,am] = max(x);
tabplot;plot(am);
tabplot;plot((1:numel(am))*10,am*newDT*10*(3*10^8)/2*1000)