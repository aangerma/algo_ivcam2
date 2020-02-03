fname = 'LddInTempDB.xlsx';
fullfname = fullfile(fileparts(mfilename('fullpath')),fname);

load(fullfile(fileparts(mfilename('fullpath')),'model.mat'));
m1 = params(1);
m2 = params(2);

calTempTarget = 40;
calDac = 63;

% model testing
units = sheetnames(fullfname);
Res = [];
for i=1:length(units)
    [num,txt,raw] =xlsread(fullfname,units{i});
    txt = strtrim(txt(1,:));
    
    idx =find(strcmp('Power',txt));
    power = num(:,idx);
    goodidx = ~isnan(power);
    power = power(goodidx);
    
    idx =find(strcmp('LDD',txt));
    temps = num(goodidx,idx);
    
    
    idx =find(strcmp('RegVal',txt));
    dac = num(goodidx,idx);
    
    
    [u,ua,uidxs] = unique(dac);
    figure(i),clf;
    hold on;
    tidx = minind(double(dac ~= calDac)*1000+abs(temps-calTempTarget));
    calPower = power(tidx);
    calTemp = temps(tidx);
    calPowerDac0 =  power( minind(double(dac ~= 0)*1000+abs(temps-calTempTarget)));
    
    UnitRes = [];
    for relPoint = 1:length(u)
        uTemps = temps(relPoint == uidxs);
        uPower = power(relPoint == uidxs);
        
        deltaT = (uTemps-calTemp);
        predictedPower = (calPowerDac0 + (calPower-calPowerDac0)*u(relPoint)/calDac) + (u(relPoint)*m1+m2).*(uTemps-calTemp);
        dac_predicted = (uPower-calPowerDac0 - m2*deltaT)./((calPower-calPowerDac0)./calDac+m1*deltaT);
        plot(uTemps,uPower,'r',uTemps,predictedPower,'b');
        %plot(uTemps,dac_predicted,'r',uTemps,dac(relPoint == uidxs),'b');
        UnitRes = [UnitRes ;[predictedPower uPower]];
    end
    title(units{i});
    xlabel('Temprature offset');
    ylabel ('measured power');
    
    Res = [Res ; UnitRes];
    
    errs = diff(UnitRes(:,1:2),1,2);
    vidxs = abs(errs)<10;
    rmsPower = sqrt(mean(errs(vidxs).^2));
    maePct = mean(abs(errs(vidxs)./UnitRes(vidxs,2)))*100;
    fprintf('units %s : model fit RMS error: %gmV MAE: %g%%\n' ,units{i},rmsPower,maePct);
    
end
errs = diff(Res(:,1:2),1,2);
vidxs = abs(errs)<10;
rmsPower = sqrt(mean(errs(vidxs).^2));
maePct = mean(abs(errs(vidxs)./Res(vidxs,2)))*100;
fprintf('model fit RMS error: %gmV MAE: %g%%\n' ,rmsPower,maePct);