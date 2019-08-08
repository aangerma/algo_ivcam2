clear variables
clc

%% Definitions

% thermal loop
samplingTime = 20; % [sec] for checking status
dTempThresh = 3; % [deg] for initiating calibration
t_timeout = 30*60; % [sec] for termination

% calibration parameters
calibParams.gnrl.Nof2avg = 30;
calibParams.dataDelay.fastDelayInitVal = 98690;
calibParams.dataDelay.slowDelayInitVal = 98583;
calibParams.dataDelay.iterFixThr = 1;
calibParams.dataDelay.nAttempts = 20;
calibParams.dataDelay.calibrateFast = 1;
calibParams.dataDelay.sphericalScaleFactors = [1 1];

% run parameters
% res = [480,640]; outputFolderBasic = 'D:\temp\delayPerTempVGA\';
res = [768,1024]; outputFolderBasic = 'D:\temp\delayPerTempXGA\';

%% Initializations

% stream initiation
hw = HWinterface();
hw.cmd('dirtybitbypass')
unitInfo = hw.getInfo;
ind = strfind(unitInfo, 'OpticalHeadModuleSN:          ');
serialNum = unitInfo(ind+30:ind+37);
hw.startStream(0,res)
hw.setReg('DIGGsphericalEn',1);
hw.write('DIGGsphericalScale',uint32(56886272))
hw.shadowUpdate();
Calibration.dataDelay.setAbsDelay(hw, calibParams.dataDelay.fastDelayInitVal, calibParams.dataDelay.slowDelayInitVal);
nFrames = 1;
x = hw.getFrame(nFrames);
figure(1), imagesc(x.i), pause(2), close(1)

% control parameters
t0 = tic;
curr_t = toc(t0);
prev_temp = 0;
epoch = 0;
thermalTime = zeros(0,1); % [min]
thermalLdd = zeros(0,1);

% results
calibTimes = zeros(0,1); % [min]
temps = zeros(0,1); % [deg]
delays = zeros(0,2); % [IR, Z]

%% Thermal loop
fprintf('Starting thermal loop...\n')
while (curr_t < t_timeout)
    tempLdd = hw.getLddTemperature;
    % waiting for required temperature change
    while (tempLdd-prev_temp < dTempThresh) && (curr_t < t_timeout)
        pause(samplingTime)
        tempLdd = hw.getLddTemperature;
        curr_t = toc(t0);
        thermalTime = [thermalTime; curr_t/60];
        thermalLdd = [thermalLdd; tempLdd];
        figure(9853), hold on, plot(thermalTime, thermalLdd, 'b.-'), grid on, xlabel('time [min]'), ylabel('LDD [deg]'), title(serialNum)
    end
    prev_temp = tempLdd;
    % performing calibration
    fprintf('Calibrating at %.2f[deg]:\n', tempLdd)
    epoch = epoch+1;
    runParams.outputFolder = [outputFolderBasic, sprintf('calib%03d', epoch)];
    [delayRegs, delayCalibResults] = Calibration.dataDelay.calibrate(hw,calibParams.dataDelay,@fprintf,runParams,calibParams);
    curDelays = [delayCalibResults.delayIR, delayCalibResults.delayZ];
    if (epoch==1)
        refDelays = curDelays;
    end
    fprintf('IR delay = %d   ;   Z delay = %d\n', curDelays(1), curDelays(2))
    calibTimes = [calibTimes; curr_t/60];
    temps = [temps; tempLdd];
    delays = [delays; curDelays];
    figure(9853), plot(calibTimes, temps, 'ro')
    % saving pre calibration & post calibration images (with first calibration serving as reference)
    Calibration.dataDelay.setAbsDelay(hw, refDelays(2), refDelays(1));
    pause(1)
    x = hw.getFrame(nFrames);
    save([outputFolderBasic, sprintf('epoch_%d_pre.mat',epoch)], 'x')
    Calibration.dataDelay.setAbsDelay(hw, curDelays(2), curDelays(1));
    pause(1)
    x = hw.getFrame(nFrames);
    save([outputFolderBasic, sprintf('epoch_%d_post.mat',epoch)], 'x')
end
fprintf('Reached timeout after %.1f[min]\n', curr_t/60)
save(sprintf('%s.mat', serialNum), 'temps', 'delays')
hw.stopStream();
