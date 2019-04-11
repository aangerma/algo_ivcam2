function [  ] = plotLOSErrorByTemp( resArray,legendStr )

resultsMax = reshape([resArray.rptErrorsPerTempMax],[size(resArray(1).rptErrorsPerTempMax),numel(resArray)]);
resultsRMS = reshape([resArray.rptErrorsPerTempRMS],[size(resArray(1).rptErrorsPerTempRMS),numel(resArray)]);
Temp = reshape([resArray.Temp],[size(resArray(1).Temp),numel(resArray)]); Temp = Temp(:,1);
figure,
subplot(231);
plot(Temp,squeeze(resultsMax(1,:,:)));title('Max Rtd Diff From Ref');xlabel('Temperature'); ylabel('mm');legend(legendStr);
subplot(234);hold on
plot(Temp,squeeze(resultsRMS(1,:,:)));title('RMS Rtd Diff From Ref');xlabel('Temperature'); ylabel('mm');legend(legendStr);
subplot(232);hold on
plot(Temp,squeeze(resultsMax(2,:,:)));title('Max X Pixel Diff From Ref');xlabel('Temperature'); ylabel('Pixels');legend(legendStr);
subplot(235);hold on
plot(Temp,squeeze(resultsRMS(2,:,:)));title('RMS X Pixel Diff From Ref');xlabel('Temperature'); ylabel('Pixels');legend(legendStr);
subplot(233);hold on
plot(Temp,squeeze(resultsMax(3,:,:)));title('Max Y Pixel Diff From Ref');xlabel('Temperature'); ylabel('Pixels');legend(legendStr);
subplot(236);hold on
plot(Temp,squeeze(resultsRMS(3,:,:)));title('RMS Y Pixel Diff From Ref');xlabel('Temperature'); ylabel('Pixels');legend(legendStr);

end

