close all
clear variables
clc

% Calibration info for F9280051
eeprom.IR_slope     = 0.94;
eeprom.IR_offset    = 98310.7;
eeprom.Z_slope      = 0.81;
eeprom.Z_offset     = 98432.9;
eeprom.T_ref        = 54.2363663;

% Initializations
testDuration    = 20*60; % [sec]
maxDelta        = 0.2; % [deg]
pauseTime       = 30; % [sec]
res             = [480,640]; % VGA
nFrameToAv      = 30;
Tldd            = zeros(0,1);
hTrans          = cell(0,1);

hw = HWinterface();
hw.cmd('dirtybitbypass');
syncLoopFlag = 1;
% syncLoopFlag = 0;
hw.setAlgoLoops(syncLoopFlag, true);
hw.startStream(0,res);

% Actual test
t0                  = tic;
t                   = toc(t0);
while (t < testDuration)
    t = toc(t0);
    curTemp = hw.getLddTemperature;
    if ~isempty(Tldd) && (curTemp-Tldd(end)<maxDelta)
        break
    end
    Tldd(end+1,1) = hw.getLddTemperature;
    x = hw.getFrame(nFrameToAv);
    [res, dbg] = Validation.aux.edgeTrans(x.i);
    hTrans{end+1,1} = dbg.hTrans;
    fprintf('Tldd = %.2f, mean sharpness = %.2f\n', Tldd(end), mean(hTrans{end}(:)))
    pause(pauseTime)
end

% Finalization
hw.stopStream();
save(sprintf('sharpness_results_SL%d.mat',syncLoopFlag), 'Tldd', 'hTrans')
