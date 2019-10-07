function [] = AnalyzeAverageCode(OrigCode,Data)
%% average fast data
aveData=mean(Data,2); 
figure(); 
x=1:length(OrigCode.tCode);
plot(x,OrigCode.tCode,x,aveData); legend('tx-code','Ave- sampeled channel'); ylim([-0.2,1.2]); 
grid minor; 
end

