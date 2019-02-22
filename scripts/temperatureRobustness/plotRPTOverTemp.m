function plotRPTOverTemp(framesPerTemperature,regs,tmpBinEdges)
X = [];
Y = [];
RTD =[];
tmps = [];
for i = 1:numel(framesPerTemperature)
    frame = framesPerTemperature{i};
    if isempty(frame)
       continue; 
    end
    

   rpt = reshape([frame.rpt],[20*28,3,numel(frame)]);
   rpt = mean(rpt,3);
   [x,y] = Calibration.aux.ang2xySF(Calibration.Undist.applyPolyUndist(rpt(:,2),regs),rpt(:,3),regs,[],1); 
   tmps = [tmps,tmpBinEdges(i)];
   RTD = [RTD,rpt(:,1)];
   X = [X,x(:)];
   Y = [Y,y(:)];
end

figure,
tabplot;
plot(tmps,X);
xlabel('Ldd temperature');
ylabel('Corner X location');
title('Corner X location over temp')

tabplot;
plot(tmps,Y);
xlabel('Ldd temperature');
ylabel('Corner Y location');
title('Corner Y location over temp')

tabplot;
plot(tmps,RTD);
xlabel('Ldd temperature');
ylabel('Corner RTD value');
title('Corner RTD value over temp')



end

