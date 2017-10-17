clear
rng(0)

noiseStdNvals = 100;
randItrNvals = 1000;
Fc = 10;
t_c = 0:1/Fc:26-0.1;

N = length(t_c);
[aaa,bbb,ccc]=Codes.Barker13(1);
txA = Utils.binarySeq(t_c,aaa,1)*sqrt(2);
txB = Utils.binarySeq(t_c,ccc,2);




kerA = Utils.binarySeq(t_c,bbb,1);
kerB = Utils.binarySeq(t_c,ccc,2)/2;



F=logspace(log10(0.1),log10(5),noiseStdNvals);

pslrA=zeros(noiseStdNvals,randItrNvals);
pslrBK13 =zeros(noiseStdNvals,randItrNvals);



snrA_db = 10*log10(sqrt(mean(txA.^2))./F);
snrB_db = 10*log10(sqrt(mean(txB.^2))./F);

parfor z=1:randItrNvals
    n = randn(1,length(t_c));
    

    
    for i=1:noiseStdNvals

        
        
        nA = n*F(i);

        txnA = txA +nA;
        cA = conv(txnA,fliplr(kerA))/Fc;
        ccA=sort(cA([1:N-Fc N+Fc:end]));ccA=ccA(end);
        if(any(cA(N-Fc:N+Fc)>max(ccA,cA(N) )))
            ccA = max(cA(N-Fc:N+Fc));
        end
        pslrA(i,z) = cA(N)/ccA;
        
        nB = n*F(i);

        txnB = txB +nB;
        cB = conv(txnB,fliplr(kerB))/Fc;
        ccB=sort(cB([1:N-2*Fc N+2*Fc:end]));ccB=ccB(end);
        if(any(cB(N-2*Fc:N+2*Fc)>max(ccB,cB(N)) ))
            ccB = max(cB(N-2*Fc:N+2*Fc));
        end
        pslrBK13(i,z) = cB(N)/ccB;
%            plot((-N+1:N-1)/Fc,cB,'g',([N find(cB==ccB,1)]-N)/Fc,[cB(N) ccB],'g.',...
%                (-N+1:N-1)/Fc,cA,'r',([N find(cA==ccA,1)]-N)/Fc,[cA(N) ccA],'r.',...
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