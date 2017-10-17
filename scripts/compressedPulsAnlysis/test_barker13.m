%%OPTIMAL
[tx,ker,c]=Codes.barker13();
%crr = conv(c,fliplr(c));
%  crr = conv(tx,fliplr(ker));
crr = (Utils.correlator(ker,circshift(tx,[0 round(length(tx)/2)])))
 subplot(211);
 bar(tx);axis tight;set(gca,'ylim',[0 1.5]);
 subplot(212);
plot(crr);axis tight;



%%
 rng(100)
SNR_db = 100;


[tx,ker,bk]=Codes.barker13();

Tc=1/100;
 
  Ts=1/5;


t_c = 0:Tc:length(ker)*2-Tc;
t_s = 0:Ts:length(ker)*2-Ts;


offset = length(ker)/2;

y_c = Utils.binarySeq(t_c+offset,repmat(tx(:)',1,100),1);

noiseStdev = sqrt(mean(y_c.^2))/10^(SNR_db/10);
nv = randn(size(y_c))*noiseStdev;
yn_c = y_c + nv;


tc2indx = @(t) round((t-t_c(1))/Tc+1);

tsampler_c = (0:Tc:Ts);


indices=tc2indx(bsxfun(@plus,tsampler_c,(0:length(t_s)-1)'*Ts));


yn_s = sum(yn_c(indices),2)*Tc/Ts;
y_s = sum(y_c(indices),2)*Tc/Ts;

k_s=Utils.binarySeq(0:Ts:length(ker)-1,ker,1);

% c=conv(yn_s,fliplr(k_s),'same')*Ts;
c=Utils.correlator(yn_s,k_s);
subplot(411);
plot(t_c,nv,t_c,y_c);
title('signal(continous), noise (continous)');
subplot(412);
plot(t_c,yn_c)
title('signal+noise (continous)');
subplot(413);
plot(t_s,yn_s,'.-',t_s,y_s)
title('signal(sampled), signal+noise (sampled)');
subplot(414);
plot(0:Ts:(length(c)-1)*Ts,c','.-');
title('correlation(sampled)');

