fname = 'LddInTempDB.xlsx';
fullfname = fullfile(fileparts(mfilename('fullpath')),fname);

units = sheetnames(fullfname);
P = zeros(2,1,1);
allData = [];

%data collection
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
    figure(1),clf;
    hold on;
    allData = [allData;[dac power temps]]; %#ok<*AGROW>
    for uid = 1:length(u)
        uTemps = temps(uid == uidxs);
        tidx = minind(abs(uTemps-calTempTarget));
        uTemps = uTemps - uTemps(tidx);
        uPower = power(uid == uidxs);
        uPower = uPower -uPower(tidx);
        plot(uTemps,uPower);
        
        p = [uTemps ones(size(uTemps))]\uPower;
        rng_x = min(uTemps):max(uTemps);
        vals = polyval(p,rng_x);
        plot(rng_x,vals)
        P(:,uid,i) = p;
    end
end
%model calibration
mdl = median(P,3);
params = [u ones(size(u))]\mdl(1,:)';
figure(2);
plot(u,mdl(1,:),'r',u,polyval(params,u),'b');

title('dac to power slope over temperature as a function of the dac');
xlabel('Dac values');
ylabel ('Slope');
legend({'average on units','fitted'});


% model testing

calTempTarget = 40;
calDac = 63;

Res = [];
for i=1:length(units)
    [num,txt,raw] =xlsread(fullfname,units{i});
    txt = strtrim(txt(1,:));
    
    idx =find(strcmp('Power',txt));
    power = num(:,idx); %#ok<*FNDSB>
    
    idx =find(strcmp('LDD',txt));
    temps = num(:,idx);
    
    
    goodidx = ~isnan(power)& temps>5 & temps<70;
    power = power(goodidx);
    temps = temps(goodidx);
    
    idx =find(strcmp('RegVal',txt));
    dac = num(goodidx,idx);
    [u,ua,uidxs] = unique(dac);
    figure(2+i),clf;
    hold on;
    tidx = minind(double(dac ~= calDac)*1000+abs(temps-calTempTarget));
    calPowerDac0 =  power( minind(double(dac ~= 0)*1000+abs(temps-calTempTarget)));
    
    calPower = power(tidx);
    calTemp = temps(tidx);
    unitRes = [];
    for relPoint = 1:length(u)
        uTemps = temps(relPoint == uidxs);
        uPower = power(relPoint == uidxs);
        predictedPower = (calPowerDac0 + (calPower-calPowerDac0)*u(relPoint)/calDac) + (u(relPoint)*params(1)+params(2)).*(uTemps-calTemp);
        plot(uTemps,predictedPower,'r',uTemps,uPower,'b');
        unitRes = [unitRes ;[predictedPower uPower]];
    end
    
    errs = diff(unitRes,1,2);
    vidxs = abs(errs)<10;
    rmsPower = sqrt(mean(errs(vidxs).^2));
    maePct = mean(abs(errs(vidxs)./unitRes(vidxs,2)))*100;
    fprintf('unit %s: model fit RMS error: %gmV MAE: %g%%\n' ,units{i},rmsPower,maePct);
    
    title(sprintf('unit %s: model fit RMS error: %gmV MAE: %g%%' ,units{i},rmsPower,maePct));
    xlabel('Temprature [C]');
    ylabel ('measured power [mV]');
    legend({'predicted','measured'});
    Res = [Res;unitRes];
    
    
    
end
errs = diff(Res,1,2);
vidxs = abs(errs)<10;
rmsPower = sqrt(mean(errs(vidxs).^2));
maePct = mean(abs(errs(vidxs)./Res(vidxs,2)))*100;
fprintf('all units: model fit RMS error: %gmV MAE: %g%%\n' ,rmsPower,maePct);