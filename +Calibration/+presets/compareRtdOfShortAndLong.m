function rtd2add2short = compareRtdOfShortAndLong(hw,calibParams,res,runParams)
params = Validation.aux.defaultMetricsParams();
params.roi = calibParams.presets.compare.roi; params.isRoiRect=1; 
mask = Validation.aux.getRoiMask(res, params);
N = calibParams.presets.compare.nTrials;
for i = 1:N
    for p = 1:2
        hw.stopStream;
        hw.setPresetControlState(p);
        hw.startStream(0,res);
        r=Calibration.RegState(hw);
        r.add('JFILinvBypass',true);
        r.add('DESTdepthAsRange',true);
        r.add('DESTbaseline$',single(0));
        r.add('DESTbaseline2$',single(0));
        r.set();
        hw.getFrame(30);
        frame(p) = hw.getFrame(30);
    end
    hw.stopStream;
    diff(i) = mean(single(frame(1).z(mask))/4*2) - mean(single(frame(2).z(mask))/4*2);
end
rtd2add2short = mean(diff);
if ~isempty(runParams)
    ff = Calibration.aux.invisibleFigure();
    plot(diff);title('Rtd Long-Short'); ylabel('mm'); xlabel('trial #');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Presets','CompareMeanZPostBurning'); 
end
end