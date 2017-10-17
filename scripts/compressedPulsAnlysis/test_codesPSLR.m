clear
rng(0)



Nrand = 3000;
NstdVals = 100;


VERBOSE=false;

F = logspace(log10(0.03),log10(3),NstdVals);

i=1;
[S(i).tx,S(i).kr]=Codes.Barker13(1);
S(i).name = 'BK13M(26)';
i=i+1;
% 
% 
[S(i).tx,S(i).kr]=Codes.ðarker13();
S(i).name = 'BK13M(52)';
 i=i+1;
 
 
S(i).tx=[1 zeros(1,25)];
S(i).kr=S(i).tx;
S(i).name = 'Delta26';
i=i+1;



S(i).tx=[1 zeros(1,51)];
S(i).kr=S(i).tx;
S(i).name = 'Delta52';
i=i+1;


 
%  [S(i).tx,S(i).kr]=Utils.ipatov13(0);
%  S(i).name = 'IPTV13';
% 
% 
% 
% i=i+1;
% S(i).tx=[0 0 0 1 1 0 0 1 0 1 0 0 0];
% S(i).kr = S(i).tx*2-1;
% S(i).name = 'PROP13a';
% 
% i=i+1;
% S(i).tx=[0 1 0 1 0 1 0 0 1 0 0 0 0];
% S(i).kr = S(i).tx*2-1;
% S(i).name = 'PROP13b';



% S(2).tx = [1 1 1 1 1 1 1 1 1 0 0 1 0 1 0 1 0 0 1 1 0 0 0 0 0 0 0 1 1];
% S(2).kr = [0.198;0.174;0.019;-0.053;-0.071;-0.016;-0.008;-0.035;-0.006;-0.257;-0.129;0.121;0.156;0.139;-0.041;0.015;-0.017;-0.018;0.235;0.222;-0.354;-0.333;-0.179;-0.233;0.066;-0.338;0.124;-0.538;-0.398;0.683;0.425;0.365;0.073;0.265;0.196;0.354;0.422;1.012;-0.854;-1.078;1.06;-1.137;1.464;-1.415;0.967;-0.912;-1.045;1.755;1.376;-0.904;-0.261;0.014;-0.812;-0.028;-0.019;-1.12;1.652;1.244;-0.512;-0.465;-0.165;-0.573;0.036;0.113;-0.279;0.337;0.634;0.066;-0.07;-0.269;-0.113;-0.044;0.059;-0.051;-0.29;-0.043;0.368;0.276;0.027;0.008;-0.14;-0.173;-0.045;-0.274;-0.195;0.257;0.333]';
% S(2).name = 'LEV29';
%
%
% S(3).tx =[1 1 1 1 1 1 1 1 1 0 0 1 0 1 0 1 0 0 1 1 0 0 0 0 0 0 0 1 1];
% S(3).kr = [0.198 0.174 0.019 -0.0795 -0.1065 -0.024 -0.012 -0.0525 -0.009 -0.3855 -0.1935 0.121 0.156 0.139 -0.0615 0.015 -0.0255 -0.027 0.235 0.222 -0.531 -0.4995 -0.2685 -0.3495 0.066 -0.507 0.124 -0.807 -0.597 0.683 0.425 0.365 0.073 0.265 0.196 0.354 0.422 1.012 -1.281 -1.617 1.06 -1.7055 1.464 -2.1225 0.967 -1.368 -1.5675 1.755 1.376 -1.356 -0.3915 0.014 -1.218 -0.042 -0.0285 -1.68 1.652 1.244 -0.768 -0.6975 -0.2475 -0.8595 0.036 0.113 -0.4185 0.337 0.634 0.066 -0.105 -0.4035 -0.1695 -0.066 0.059 -0.0765 -0.435 -0.0645 0.368 0.276 0.027 0.008 -0.21 -0.2595 -0.0675 -0.411 -0.2925 0.257 0.333];
% S(3).name = 'LEV29 modified';


% s1=double('---++---+-++-+-+-++--+----'*1<44);
% s2=double('----+--++-+-----+-+++--+++'*1<44);
% 
% S(i).tx=[s1 s2];
% S(i).kr = S(i).tx*2-1;
% S(i).name='GOLAY26(52)';
% i=i+1;



S(i).tx=[0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 1 0 1 0 0 0];
S(i).kr = S(i).tx*2-1;
S(i).name='PROP_e(26)';
i=i+1;



S(i).tx=[0 0 0 0 1 1 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 1];
S(i).kr = S(i).tx*2-1;
S(i).name='PROP_f(52)';
i=i+1;


% 

S(i).tx=[0 0 0 0 0 0 1 1 1 1 0 0 1 1 1 0 1 1 0 0 1 0 1 0 1 1 1 1 0 1 0 1 0 0 1 1 0 1 1 1 0 0 1 1 1 1 0 0 0 0 0 0];
S(i).kr = S(i).tx*2-1;
S(i).name='PROP_e(52)';
i=i+1;




for i=1:length(S)
    S(i).tx = S(i).tx/sqrt(mean(S(i).tx.^2));
end

for i=1:length(S)
    %correlation size should be N
%         N = 20;
%         nn = (N-1)/2;
%         pAL = round((N-length(S(i).tx))/2);
%         pAR = N-length(S(i).tx)-pAL;
%         S(i).txp = [zeros(1,pAL) S(i).tx zeros(1,pAR)];
        txn = length(S(i).tx);
        txhn = round(txn/2);
        S(i).txp = S(i).tx([txhn+1:txn 1:txn 1:txhn-1]);

        S(i).snr=10*log10(sqrt(mean(S(i).txp.^2))./F);
    S(i).pslr = zeros(NstdVals,Nrand);
end
col = lines(length(S));

for z=1:Nrand
         n = randn(1,max(cellfun(@(x) length(x),{S.txp})));
    for i=1:NstdVals
                 ns = n*F(i);
        if(VERBOSE)
            cla;
        end
        for sss=1:length(S)

            txnA = S(sss).txp +ns(1:length(S(sss).txp));
                c = conv(txnA,fliplr(S(sss).kr),'valid');
            
            pkLoc = floor(length(c)/2)+1;
            
            
            [smx,smxi]=max([c(1:pkLoc-1) -inf c(pkLoc+1:end)]);
%                pslr =10*log10(max(0,c(pkLoc)/smx));
                pslr =(c(pkLoc)-smx);
            S(sss).pslr(i,z) = pslr;
            
            
            
            if(VERBOSE)
                hold on
                plot(c,'color',col(sss,:));
                plot([pkLoc smxi],[c(pkLoc) smx],'.','color',col(sss,:),'markersize',20);
                
                hold off
            end
        end
        
        if(VERBOSE)
            axis tight
            drawnow;
        end
    end
    %
end
%%
col = lines(length(S));
P=50;
for i=1:length(S)
    S(i).pslr_m=prctile(S(i).pslr,P,2);
end

clf;
subplot(5,1,1);
hold on
for i=1:length(S)
    stem(S(i).tx,'color',col(i,:),'linewidth',2);
end
hold off

subplot(5,1,2:5);
cla
hold on
for i=1:length(S)
    plot(S(i).snr,S(i).pslr_m,'color',col(i,:),'linewidth',2);
end
line(get(gca,'xlim'),[0 0],'color','r');
hold off
grid on
xlabel('OSNR[db]');

legend({S.name},'location','southeast');
