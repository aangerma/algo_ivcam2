function [vfstOut,vslwOut,tSampler] = analogPipe(vfst,vslw,dt,regs)
%% slow+fast HPF





[bhp,ahp] = butter(3,regs.POCU.hpfCutoffMHZ*1e-3/(.5/dt),'high');
vfst=filter(bhp,ahp,vfst);
vslw=filter(bhp,ahp,vslw);

%% Process Slow channel (IR)


%===BPF===
BPw = [0.250 0.500]; %GHz
[b,a]=butter(3,BPw/((1/dt)/2));
vslw1 = filter(b,a,vslw);
% vslw1=vslw;

%===AmpDet non-linear gain===
curve_type = regs.POCU.curveType; % 0-3
[ Vin,LUTlp,LUThp, hLP, hHP ] = io.POC.ampDet( dt,curve_type );
vLP = filter(hLP.num{:},hLP.den{:},vslw1);
vHP = filter(hHP.num{:},hHP.den{:},vslw1);

vLP1 = interp1(Vin,LUTlp,vLP,'spline','extrap');
vHP1 = interp1(Vin,LUThp,vHP,'spline','extrap');

vslw1_5 = vLP1+vHP1;

%===abs===
vslw2 = abs(vslw1_5);


%===LPF===
tSampler = 1/regs.POCU.irSampleFreq;
wn = (regs.POCU.irSampleFreq/2)/((1/dt)/2);
[b,a]=butter(3,wn,'low');
vslw3 = filter(b,a,vslw2);
%===ADC===
vslwOut = interp1((0:length(vslw3)-1)*dt,vslw3,(0:tSampler:length(vslw3)*dt-tSampler));






vfstOut = vfst;
end




% % % function params = pocConfigSelector(fnFull)
% % %     v={};
% % %     nch = 0;
% % %     while(true)
% % %         try
% % %             [t,v{nch+1}]=io.POC.importScopeDataWpolarity(fnFull,nch+1);
% % %         catch
% % %             break;
% % %         end
% % %         nch=nch+1;
% % %     end
% % %     t = t*1e9;
% % %
% % %
% % %
% % %     params.frameTime  = params.frameTime *1e9;
% % %     TX_TIME = input('Bin time(nsec)[1]:');
% % %     if(isempty(TX_TIME))
% % %         TX_TIME = 1;
% % %     end
% % %     TX_SEQ = input('TX sequence[barker]:');
% % %     if(isempty(TX_SEQ))
% % %         TX_SEQ = Codes.barker13();
% % %     end
% % %     params.slowChannelFs = input('slow channel sampling frequency(mhz)[100]')*1e-3;
% % %     if(isempty(params.slowChannelFs))
% % %         params.slowChannelFs=100e-3;
% % %
% % %     end
% % %     params.slowChannelAAFco=params.slowChannelFs/2;
% % %     Ts = diff(t(1:2));
% % %
% % %     n = round(length(TX_SEQ)*TX_TIME/Ts);
% % %     seq = Utils.binarySeq((0:n-1)*Ts,TX_SEQ(:)',TX_TIME);
% % %     c=zeros(nch,n+1);
% % %
% % %     N = 1000;
% % %     for i=1:nch
% % %         viN = v{i}(1:min(floor(length(v{i})/(2*n)),N)*2*n);
% % %         c(i,:)=normByMax(conv(mean(reshape(viN,n*2,[]),2),flipud(seq*2-1),'valid'));
% % %     end
% % %
% % %     figure(334489);
% % %     clf;
% % %     subplot(4,1,1:3)
% % %     dispIndx = 1e5+(1:1000);
% % %     cla;
% % %     hold on
% % %     for i=1:nch
% % %         plot(t(dispIndx),v{i}(dispIndx),'linewidth',3);
% % %     end
% % %     hold off
% % %     legend(num2cell(char((1:nch)+48)));
% % %     set(gca,'color','k')
% % %     subplot(4,1,4)
% % %     cla;
% % %     hold on
% % %     for i=1:nch
% % %         plot(0:n,c(i,:),'linewidth',3)
% % %     end
% % %     hold off
% % %
% % %     set(gca,'color','k')
% % %     title('Correlation');
% % %
% % %     params.refChanIndx=input('Reference: ');
% % %     params.slowChanIndx=input('Signal(IR): ');
% % %     params.fastChanIndx=input('Signal(Depth): ');
% % %     params.syncChanIndx=input('Mirror clock: ');
% % %     params.frameTime =1/60 *1e9;
% % %
% % %
% % %      sc.ref=1;
% % %      sc.ir=2;
% % %      sc.sig=3;
% % %      sc.mir=4;
% % %
% % %
% % %
% % %
% % % end
