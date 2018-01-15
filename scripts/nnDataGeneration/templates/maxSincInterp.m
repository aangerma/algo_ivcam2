function [sampleNum] = maxSincInterp(corr)
% Interpolates the descrete function using a sinc kernel and returns the
% index of the maximal value.
lengthCorr = numel(corr);
corr = repmat(corr,3,1);
t = 1:length(corr);
ts = linspace(1+lengthCorr,2*lengthCorr,60*lengthCorr);
[Ts,T] = ndgrid(ts,t);
corr_interp = sinc(Ts - T)*corr;
% 
% plot(t,corr,'o',ts,corr_interp)
% xlabel Sample, ylabel Signal
% legend('Sampled','Interpolated','Location','SouthWest')
% legend boxoff

[~,i] = max(corr_interp);
sampleNum = ts(i)-lengthCorr;
end
