% Pseudo-Random Binary Sequence
% Generates a binary sequence at time points t
% based on the binary vector b.
% The sequence has pulses of length T with rise/fall time trise
% trise,tfall refer to rise time from 10% to 90%
function [f, df] = prbs(t, b, trise, tfall, T)

arise = min(1e99,2.1972/trise);       % tanh slopes
afall = min(1e99,2.1972/tfall);
n = find(b)-1;            % non-zero elements in the binary vector

f  = 0;
df = 0;
for k = 1:length(n),
    tk = n(k)*T;
    frise = tanh(arise*(t-tk));
    ffall = tanh(afall*(t-tk-T));
    f = f + 0.5*(frise-ffall);
    df = df + 0.5*(afall*(ffall.^2 - 1) - arise*(frise.^2 - 1));
end
