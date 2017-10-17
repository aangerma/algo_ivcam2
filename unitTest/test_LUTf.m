func = @(x) sin((x-1)*pi*3).*(x+1);
N_LUT_BIN = 13;
tLUT =linspace(0,2,N_LUT_BIN);
dt = tLUT(2)-tLUT(1);
yLUT = func(tLUT);
lutobj = LUTf(yLUT,dt);

tQ = linspace(0,2,N_LUT_BIN*2^4);
y_hat = lutobj.at(tQ);
y_grt = func(tQ);
plot(abs(y_grt-y_hat))
lutobj.memsizeKB()


subplot(211)
plot(tQ,y_grt,'-',tLUT,yLUT,'s',tQ,y_hat,'-','markersize',7,'MarkerFaceColor','r')
axis tight
legend('input function (ground truth)','LUT data','LUT appoximation');
lutobj.memsizeKB();
subplot(212)
plot(abs(y_grt-y_hat));
axis tight
legend('error from ground truth');