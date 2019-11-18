close all
clear variables
clc

% Initializations
testDuration    = 20*60; % [sec]
maxDelta        = 0.2; % [deg]
pauseTime       = 30; % [sec]
res             = [480,640]; % VGA
nFrameToAv      = 30;
Tldd            = zeros(0,1);
hTrans          = cell(0,1);
delayRegs       = zeros(0,3,'uint32');

hw = HWinterface();
hw.cmd('dirtybitbypass');
% syncLoopFlag = 1;
syncLoopFlag = 0;
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
    delaySlow = hw.read('EXTLconLocDelaySlow');
    delayFastC = hw.read('EXTLconLocDelayFastC');
    delayFastF = hw.read('EXTLconLocDelayFastF');
    delayRegs(end+1,:) = [delaySlow, delayFastC, delayFastF];
    x = hw.getFrame(nFrameToAv);
    [res, dbg] = Validation.aux.edgeTrans(x.i);
    hTrans{end+1,1} = dbg.hTrans;
    fprintf('Tldd = %.2f, mean sharpness = %.2f\n', Tldd(end), mean(hTrans{end}(:)))
    pause(pauseTime)
end

% Finalization
hw.stopStream();
save(sprintf('sharpness_results_SL%d.mat',syncLoopFlag), 'Tldd', 'delayRegs', 'hTrans')


