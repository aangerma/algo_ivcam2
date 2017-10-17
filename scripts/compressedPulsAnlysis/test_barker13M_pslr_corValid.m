clear
rng(0)

noiseStdNvals = 100;
randItrNvals = 1000;
Fc = 10;
t_c1 = 0:1/Fc:26-0.1;
t_c2 =(0-13):1/Fc:(26-0.1+13);
N = length(t_c1);
[aaa,bbb,ccc]=Codes.Barker13(1);
txA = Utils.binarySeq(t_c2,aaa,1)*sqrt(2);
txB = Utils.binarySeq(t_c2,ccc,2);




kerA = Utils.binarySeq(t_c1,bbb,1);
kerB = Utils.binarySeq(t_c1,ccc,2)/2;



F=logspace(log10(0.1),log10(5),noiseStdNvals);

pslrA=zeros(noiseStdNvals,randItrNvals);
pslrBK13 =zeros(noiseStdNvals,randItrNvals);



snrA_db = 10*log10(sqrt(mean(txA.^2))./F);
snrB_db = 10*log10(sqrt(mean(txB.^2))./F);

parfor z=1:randItrNvals
    n = randn(1,length(t_c2));
    

    
    for i=1:noiseStdNvals

        
        
        nA = n*F(i);

        txnA = txA +nA;
        cA = conv(txnA,fliplr(kerA),'valid')/Fc;
        ccA=sort(cA([1:N/2+1-Fc N/2+1+Fc:end]));ccA=ccA(end);
        if(any(cA(N/2+1-Fc:N/2+1+Fc)>max(ccA,cA(N/2+1) )))
            ccA = max(cA(N/2+1-Fc:N/2+1+Fc));
        end
        pslrA(i,z) = cA(N/2+1)/ccA;
        
        nB = n*F(i);

        txnB = txB +nB;
        cB = conv(txnB,fliplr(kerB),'valid')/Fc;
        ccB=sort(cB([1:N/2+1-2*Fc N/2+1+2*Fc:end]));ccB=ccB(end);
        if(any(cB(N/2+1-2*Fc:N/2+1+2*Fc)>max(ccB,cB(N/2+1)) ))
            ccB = max(cB(N/2+1-2*Fc:N/2+1+2*Fc));
        end
        pslrBK13(i,z) = cB(N/2+1)/ccB;
%            plot((-N/2:N/2)/Fc,cB,'g',([(N/2+1) find(cB==ccB,1)]-N/2-1)/Fc,[cB(N/2+1) ccB],'g.',...
%                (-N/2:N/2)/Fc,cA,'r',([(N/2+1) find(cA==ccA,1)]-N/2-1)/Fc,[cA(N/2+1) ccA],'r.',...
%               'markersize',30);
%           set(gca,'ylim',[-30 30]);
%          drawnow;
    end
    
end
%%
p = 50;
maxPSLR = 10;
pslrA_m=prctile(pslrA,p,2);
pslrB_m=prctile(pslrBK13,p,2);

plot(snrA_db,10*log10(pslrA_m),snrB_db,10*log10(pslrB_m))
 xlabel('OSNR[db]');
 ylabel('PSLR[db]');
 grid on
 axis tight
 line(get(gca,'xlim'),[1 1]*10*log10(1+maxPSLR/100),'color','r');
 title(sprintf('Minimum success ratio: %d%%, PSLR margin: %d%%',p,maxPSLR));
% 
 legend('Barker 13M','Barker 13','location', 'SouthEast'   );