%initialize
hw = HWinterface();
gains = [255:-1:50 50:1:255 255:-1:50 50:1:255];
I = zeros(1,length(gains));
depths = zeros(1,length(gains));
intesity = zeros(1,length(gains));
ROI = [192 , 288 ; 256, 384];

%set to Rtd
hw.getFrame(1); %need toi start streaming
r=Calibration.RegState(hw);
r.add('RASTbiltBypass'     ,true       );
r.add('JFILbypass$'        ,true       );
r.add('depthAsRange'       ,true       );
r.add('DESTbaseline$'      ,single(0.0));
r.add('JFILbypass$'        ,false      );
r.add('JFILbypassIr2Conf'  ,true       );
r.set(); 

% warm up
hw.cmd('iwb e2 03 01 90'); %set mode mod_strobe
t=tic;
while toc(t) < 60
    modstrobeFrame = hw.getFrame(30);
end

%configure to uniform and read parameters
hw.cmd('iwb e2 03 01 10'); %set mode I2c mod_dac
[~,bias] = hw.cmd('irb e2 06 01'); %read bias
[~,modRef] = hw.cmd('irb e2 0a 01'); %read modulation_ref


sn = hw.getSerial();
bias = double(bias);
modRef = double(modRef);

%capture reference frame
hw.cmd(sprintf('iwb e2 08 01 %02x',gains(1)));%set mod_dac
for  i = 1:3
    refFrame = hw.getFrame(10);
end
refFrame.z = double(refFrame.z);
refFrame.z(refFrame.z ==0) = NaN;
frames = refFrame;

%measure depth changes as function of the current
for i = 1:length(gains)
    hw.cmd(sprintf('iwb e2 08 01 %02x',gains(i)));
    I(i) = gains(i)/ 255.0 * (modRef/63 + 1)*150.0 + bias*60.0/255.0;
    frame = hw.getFrame(25);
    frame.z = double(frame.z);
    frame.z(frame.z ==0) = NaN;
    frames(i+1) = frame;
    relFrame = frames(i+1).z - refFrame.z;
    relFrame = relFrame(ROI(1,1):ROI(1,2),ROI(2,1):ROI(2,2));
    depths(i) = nanmean(relFrame(:));
    intesity(i) = mean(mean(double(frames(i+1).i)));
end

%plot
figure(1);clf;
plot(I,depths./8,'b');
[uniqI,~,ic] = unique(I);
ac = accumarray(ic,depths,[],@mean);
hold on;
plot(uniqI,ac./8,'r');
hold off;
title('depth delta wrt laser current');
legend('data','average');

save(sprintf('txPwr_%s.mat',sn),'sn','I','depths','frames','gains',...
    'bias','modRef','ROI','modstrobeFrame','intesity','-v7.3');
delete(r);
clear hw;

%recording

if false
    %load()
    minIdx = 34;
    refFrame = frames(minIdx);
    refFrame.z = double(refFrame.z);
    refFrame.z(refFrame.z ==0) = NaN;
    I = [] ;
    depths = [];
    for i = (minIdx+1):length(gains)
        I(i- minIdx) = double(gains(i))/ 255.0 * (double(modRef)/63 + 1)*150.0 + double(bias)*60.0/255.0;
        frame = frames(i+1);
        frame.z = double(frame.z);
        frame.z(frame.z ==0) = NaN;
        relFrame = frame.z - refFrame.z;
        relFrame = relFrame(ROI(1,1):ROI(1,2),ROI(2,1):ROI(2,2));
        depths(i - minIdx) = nanmean(relFrame(:));
    end
    plot(I,depths./8);

end