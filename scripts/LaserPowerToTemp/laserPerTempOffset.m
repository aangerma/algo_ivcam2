zRes = [768 1024];
offset = 200;
roi = repmat(zRes/2,2,1) + repmat([-offset; offset],1,2);%[100 768-100;100 1024-100];
if ~exist('hw','var')
    hw = HWinterface;
    hw.setPresetControlState(1);
    hw.cmd('ALGO_THERMLOOP_MODE_SET 7 10');
    hw.startStream([],zRes);
    hw.getFrame;
end

vals = 0:2:100;
Zmean = zeros(1,length(vals));
Imean = zeros(1,length(vals));
for j=1:2
    hw.setPresetControlState(j);
    hw.getFrame(30);
    for i=1:length(vals)
        hw.cmd(sprintf('amcset 5 %x',vals(i)));
        hw.getFrame(30);
        frames = hw.getFrame(30);
        z = double(frames.z)/double(hw.z2mm);
        z(z==0)= NaN;
        Zmean(j,i) = nanmean(vec(z(roi(1,1):roi(1,2),roi(2,1):roi(2,2))));
        Imean(j,i) = nanmean(vec(frames.i(roi(1,1):roi(1,2),roi(2,1):roi(2,2))));
    end
end
figure();
subplot(2,1,1),plot(Zmean');
subplot(2,1,2),plot(Imean');

