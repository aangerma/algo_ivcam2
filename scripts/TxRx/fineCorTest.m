cor_dec = Utils.correlator(uint16(cma), uint8(flip(TxFullcode)));
[~, maxIndDec] = max(cor_dec);
peak_index = maxIndDec-1;
peak_index = permute(peak_index,[2 1]);
max_dist=sample_dist*length(TxFullcode);

roundTripDistance = peak_index .* sample_dist;
zValue = mod(roundTripDistance-system_delay,max_dist)';

AbsdiffError=abs(zValue-median(zValue)); 
figure(); plot(AbsdiffError,'*'); grid minor;  title('d=350 code 16x4: abs diff error- fine corraltion only' ); 

figure();subplot(2,2,1);  plot(cor_dec(:,13821)); title('13821 : error 93'); ylabel('cor Dec'); xlabel('index'); 
 subplot(2,2,2) ; plot(cor_dec(:,22614)); title('22614 : error 37.46');  ylabel('cor Dec'); xlabel('index'); 
subplot(2,2,3) ; plot(cor_dec(:,8441)); title('8441 : error 18.73');  ylabel('cor Dec'); xlabel('index'); 
 subplot(2,2,4) ;plot(cor_dec(:,14615)); title('14615 : error 0');  ylabel('cor Dec'); xlabel('index'); 