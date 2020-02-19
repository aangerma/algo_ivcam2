fname = 'LddInTempDB2.xlsx';
fullfname = fullfile(fileparts(mfilename('fullpath')),fname);

%model 
P = zeros(2,1,1);
calTempTarget = 40;
calDac = 60;
allData = [];
Tslope = -0.65295;
Dslope = 0.005325;
Doffset = 0.871;

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
    allData = [allData;[dac power temps]];
    
    
    [u,ua,uidxs] = unique(dac);
    figure(i),clf;
    hold on;
    tidx = minind(double(dac ~= calDac)*1000+abs(temps-calTempTarget));
    calPowerDac0 =  power( minind(double(dac ~= 0)*1000+abs(temps-calTempTarget)));
    
    calPower = power(tidx);
    calTemp = temps(tidx);
    UnitRes = [];
    for relPoint = 1:length(u)
        uTemps = temps(relPoint == uidxs);
        uPower = power(relPoint == uidxs);
        
        deltaT = (uTemps-calTemp);
        %MOD_REF = MOD_MAX – ROUND(((LDD_temp - CAL_temp) * T_slope + MOD_MAX_power ) -Target_power )* D_slope 
        expectedDp = (calDac - u(relPoint))./(Dslope*uTemps+Doffset)- Tslope*deltaT;
        actualDp = calPower - uPower;

        %plot(uTemps,uPower,'r',uTemps,predictedPower,'b');
        plot(uTemps,expectedDp,'r',uTemps,actualDp,'b');
        UnitRes = [UnitRes ;[expectedDp actualDp uPower]];
    end
    title(units{i});
    xlabel('Temprature offset');
    ylabel ('measured power');
    Res = [Res ; UnitRes];
    
    errs = diff(UnitRes(:,1:2),1,2);
vidxs = abs(errs)<10;
rmsPower = sqrt(mean(errs(vidxs).^2));
maePct = mean(abs(errs(vidxs)./UnitRes(vidxs,3)))*100;
fprintf('units %s : model fit RMS error: %gmV MAE: %g%%\n' ,units{i},rmsPower,maePct);
end
errs = diff(Res(:,1:2),1,2);
vidxs = abs(errs)<10;
rmsPower = sqrt(mean(errs(vidxs).^2));
maePct = mean(abs(errs(vidxs)./Res(vidxs,3)))*100;
fprintf('model fit RMS error: %gmV MAE: %g%%\n' ,rmsPower,maePct);