hw = HWinterface;
frame  = hw.getFrame;
r=Calibration.RegState(hw);
%% SET
r.add('RASTbiltBypass'     ,true     );
r.add('JFILbypass$'        ,true    );
r.set();

pause(3);

N = 200;
for i = 1:N
    f = hw.getFrame();
    frameZ(i,:,:) = single(f.z)/8;    
end
frameZ(frameZ == 0) = nan;

stdIm = squeeze(std(frameZ,[],1,'omitnan'));
figure,
imagesc(stdIm)
figure,
plot(frameZ(:,240,320))
title(sprintf('std=%f',std(squeeze(frameZ(:,240,320)),'omitnan')))
r.reset();