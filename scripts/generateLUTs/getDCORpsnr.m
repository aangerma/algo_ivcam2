function x
minR = 1/4;
maxR = 4;
snr = ((0:15)'*(1./(0:15)))';
snr = max(minR,min(maxR,snr));
snr = 10*log10(snr);
snr = snr
mm = 10*log10([maxR minR]);
snr = 64-round((snr-mm(1))/diff(mm)*(2^6-1))
% zeros(8)

%fast index: signal
%slow index: ambient

% lutOut.lut = LUT;
% lutOut.name = 'DCORpsnr';

end