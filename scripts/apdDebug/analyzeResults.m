load('dbg.mat');
for i = 1:numel(apdVals)
    res = split(apdVals{i});
    pwm = res{10};
    pwm = [pwm(3:4),pwm(1:2)];
    pwmVal(i) = hex2dec(pwm);
    
    tsense = res{12};
    tsense = [tsense(3:4),tsense(1:2)];
    tsenseVal(i) = hex2dec(tsense);
    
    vsense = res{14};
    vsense = [vsense(3:4),vsense(1:2)];
    vsenseeVal(i) = hex2dec(vsense);
    
end

vPoints = all(~isnan(rtdPts),2);
meanR = mean(rtdPts(vPoints,:));
figure,
plot(tim,meanR)
hold on
plot(tim,pwmVal)
grid on
hold on 
plot(tim,tsenseVal+800)
hold on 
plot(tim,vsenseeVal+800)
legend({'rtd';'pwm';'tsense';'vsense'})