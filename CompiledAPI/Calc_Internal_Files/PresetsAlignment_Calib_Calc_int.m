function [results] = PresetsAlignment_Calib_Calc_int(im, calibParams, runParams,z2mm,res)      

params = Validation.aux.defaultMetricsParams();
params.roi = calibParams.presets.compare.roi; params.isRoiRect=1; 
mask = Validation.aux.getRoiMask(res, params);

for i = 1:size(im,1)
    diff(i) = mean(single(im(i,1).z(mask))/z2mm*2) - mean(single(im(i,2).z(mask))/z2mm*2);
end
rtd2add2short = mean(diff);

Calstate = Calibration.presets.findLongRangeStateCal(calibParams,res);
results.(['rtd2add2short_',Calstate]) = rtd2add2short;


if ~isempty(runParams)
    ff = Calibration.aux.invisibleFigure();
    plot(diff);title('Rtd Long-Short'); ylabel('mm'); xlabel('trial #');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Presets','CompareMeanZPostBurning'); 
end


end
