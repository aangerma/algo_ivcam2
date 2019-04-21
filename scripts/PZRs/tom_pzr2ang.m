function [x0, x1, x2, errAngBest, tBest, errMaxAbsBest] = tom_pzr2ang(mclog)

dsmMAngX = mclog.actAngX;
dsmMAngY = mclog.actAngY;

figure; plot(dsmMAngX/25, '.-'); title('dsm angles X vs PZRs');
hold on; plot(mclog.PZR1, '.-');
hold on; plot(mclog.PZR3, '.-');
%hold on; plot(mclog.PZR2/2-0.5, '.-');
hold on; plot(mclog.angX/50, '.-');
avgAngX = conv(dsmMAngX,ones(100,1)/100);
avgAngX = avgAngX(51:end-49);
%hold on; plot(avgAngX/25, '.-');

% aPZR1 + bPZR3 - dsmMAngX = 0
% [PZR1 PZR3] [a b]' - [dsmMAngX]
%      A        x        b

% A = [mclog.PZR1 mclog.PZR3];
% b = dsmMAngX;
% x = inv(A'*A)*A'*b;

A = [mclog.PZR1 mclog.PZR3 mclog.PZR2 ones(1496,1)];
b = dsmMAngX;
x = inv(A'*A)*A'*b;
x0 = x;

optMAngX = A*x;

hold on; plot(optMAngX/25, '.-');

s=1400;
for t=1:1496-s
    %A = [mclog.PZR1(1:s) mclog.PZR3(1:s) mclog.PZR2(1+t:s+t) ones(s,1)];
    A = [mclog.PZR1(1:s) mclog.PZR3(1:s) ones(s,1)];
    b = dsmMAngX(1+t:s+t);
    x = inv(A'*A)*A'*b;
    errAng(t) = (A*x-b)'*(A*x-b);
    errMaxAbs(t) = max(abs(A*x-b))/25;
    optMAngX = zeros(1496,1);
    optMAngX(1+t:s+t) = A*x;
    %hold on; plot(optMAngX/25, '.-');
end

[errAngBest, tBest] = min(errAng);

t1=tBest;
t=t1;
    %A = [mclog.PZR1(1:s) mclog.PZR3(1:s) mclog.PZR2(1+t:s+t) ones(s,1)];
    A = [mclog.PZR1(1:s) mclog.PZR3(1:s) ones(s,1)];
    b = dsmMAngX(1+t:s+t);
    x = inv(A'*A)*A'*b;
    x1 = x;
    errAng(t) = (A*x-b)'*(A*x-b);
    errMaxAbsBest = max(abs(A*x-b))/25;
    optMAngX = zeros(1496,1);
    optMAngX(1+t:s+t) = A*x;
hold on; plot(1+t:s+t, optMAngX(1+t:s+t)/25, '.-');

%t=1271;
t2=61;
t=t2;
    %A = [mclog.PZR1(1:s) mclog.PZR3(1:s) mclog.PZR2(1+t:s+t) ones(s,1)];
    A = [mclog.PZR1(1:s) mclog.PZR3(1:s) ones(s,1)];
    b = dsmMAngX(1+t:s+t);
    x = inv(A'*A)*A'*b;
    x2 = x;
    errAng(t) = (A*x-b)'*(A*x-b);
    errMaxAbsT = max(abs(A*x-b))/25;
    optMAngX = zeros(1496,1);
    optMAngX(1+t:s+t) = A*x;
hold on; plot(1+t:s+t, optMAngX(1+t:s+t)/25, '.-');

legend('mirrorX/25', 'PZR1', 'PZR3', 'SA-slow-dsmInX', 'opt(t=0)', sprintf('opt(t=%d)',t1), sprintf('opt(t=%d)',t2) );

figure
plot(errAng, '.-');

end


