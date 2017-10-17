%%OPTIMAL
[tx,ker,bk]=Codes.golay416();
c = conv(tx,fliplr(ker))
bar(c);
%%
    [tx,ker,bk]=Codes.golay416();
    padSize = 100;
    offset = 0;
    stdev_sig = std(tx);
    stdev_noise = 0.5;
    SNR_db = 20*log10(stdev_sig/stdev_noise);
    tx = padarray(tx,[0 padSize+offset],'pre');
    tx = padarray(tx,[0 padSize-offset],'post');
    tx = tx+randn(size(tx))*stdev_noise;
    c = conv(tx,fliplr(ker),'valid');
    subplot(311);
    bar(tx)
    subplot(312);
    bar(ker)
    subplot(313);
    [mxVal,mxIndx] = max(c);
    plot(-padSize:padSize,c,mxIndx-1-padSize,mxVal,'ro');
    line([offset offset],get(gca,'ylim'),'color','g');
    title(sprintf('SNR[db]: %f',SNR_db));


%%
SNR_db = 999;


[tx,ker,bk]=Codes.Barker13(1);


T=1/1000;
t_ = 1:T:length(ker);
k_=Utils.binarySeq(t_,ker,1);

t_o = 1:T:length(ker)*2-1;
tx_o = Utils.binarySeq(t_o-length(ker)/2,tx,1);


noiseStdev = sqrt(sum(tx_o.^2)/length(tx)*T)/10^(SNR_db/10);
tx_o = tx_o + randn(size(tx_o))*noiseStdev;
c=conv(tx_o,fliplr(k_),'valid')*T;
subplot(311);
plot(t_o,tx_o)
subplot(312);
bar(t_,k_)
subplot(313);
plot(0:T:25,c);

