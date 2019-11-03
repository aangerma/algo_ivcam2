function [fast_mean,fast_std,code] = AnalyzeAverageCode(fast,transmitedCode,codeName,outFolder)
%% average fast data
 
fast_mean=mean(fast,2);
%% find ofset
cor_dec = Utils.correlator(uint16(fast_mean), (uint8(transmitedCode)));
figure();plot(cor_dec); 
[~, maxIndDec] = max(cor_dec);
peak_index = maxIndDec-1;
peak_index = permute(peak_index,[2 1]);
code = circshift(transmitedCode,peak_index); 
% h=figure(); hold all;  plot(fast_mean); plot(code);
% legend('fast mean','shiftedCode'); 
% saveas(h,strcat(outFolder,'\txAveCor',codeName,'.png'));

%%
fast_std=std(fast,0,2);



end

