function [  ] = plotAvgEGeomErrByTemp( resArray,legendStr )

resultsEGeom = reshape([resArray.eGeomErr],[size(resArray(1).eGeomErr),numel(resArray)]);
Temp = reshape([resArray.Temp],[size(resArray(1).Temp),numel(resArray)]); Temp = Temp(:,1);
figure,
plot(Temp,squeeze(resultsEGeom(:,:,:)));title('GID on Average Image');xlabel('Temperature'); ylabel('mm');legend(legendStr);

end

