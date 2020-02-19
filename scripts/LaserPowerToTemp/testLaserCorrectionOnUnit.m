%definitions
colorRes = [];%[1920 1080];%[640 480];
zRes = [768 1024];

eVal2double = @(x) (double(typecast(x,'uint16'))./100);
load(fullfile(fileparts(mfilename('fullpath')),'model.mat'));
m1 = params(1);
m2 = params(2);

if ~exist('hw','var')
    hw = HWinterface;
    [~,cdat] = hw.cmd('erb 496 2');
    calPower = eVal2double(cdat);
    [~,cdat]= hw.cmd('erb 4a5 2');
    calPowerDac0  = eVal2double(cdat);
    [~,cdat] = hw.cmd('erb 498 2');
    tcal  = eVal2double(cdat);
    [~, calDac] = hw.cmd('irb e2 09 01');
    calDac = double(calDac);
    pct2target = @(x)((calPower-calPowerDac0)*x/100+calPowerDac0);
end
[~, Ppct] = hw.cmd('AMCGET 5 0 0');
%Ppct = 28;
Pt = pct2target(Ppct);
tcurr = hw.getLddTemperature();
deltaT = tcurr-tcal;
dac_predicted = round((double(Pt-calPowerDac0) - m2*deltaT)./((calPower-calPowerDac0)./calDac+m1*deltaT));
[~, dacOnUnit] = hw.cmd('irb e2 0a 01');
fprintf('Predicted: 0x%x, on unit 0x%x\n',dac_predicted,dacOnUnit);


