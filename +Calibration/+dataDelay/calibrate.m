function [regs, results]=calibrate(hw,dataDelayParams,fprintff,runParams)

results = struct('fastDelayCalibSuccess',[],'slowDelayCalibSuccess',[],'delaySlowPixelVar',[]);

warning('off','vision:calibrate:boardShouldBeAsymmetric');
r=Calibration.RegState(hw);
%% SET
r.add('RASTbiltBypass'     ,true     );
r.add('JFILbypass$'        ,false    );
r.add('JFILbilt1bypass'    ,true     );
r.add('JFILbilt2bypass'    ,true     );
r.add('JFILbilt3bypass'    ,true     );
r.add('JFILbiltIRbypass'   ,true     );
r.add('JFILdnnBypass'      ,true     );
r.add('JFILedge1bypassMode',uint8(1) );
r.add('JFILedge4bypassMode',uint8(1) );
r.add('JFILedge3bypassMode',uint8(1) );
r.add('JFILgeomBypass'     ,true     );
r.add('JFILgrad1bypass'    ,true     );
r.add('JFILgrad2bypass'    ,true     );
r.add('JFILirShadingBypass',true     );
r.add('JFILinnBypass'      ,true     );
r.add('JFILsort1bypassMode',uint8(1) );
r.add('JFILsort2bypassMode',uint8(1) );
r.add('JFILsort3bypassMode',uint8(1) );
r.add('JFILupscalexyBypass',true     );
r.add('JFILgammaBypass'    ,false    );
r.add('DIGGsphericalEn'    ,true     );
r.add('DIGGnotchBypass'    ,true     );
r.add('DESTaltIrEn'        ,false    );
r.set();

% origBias = zeroBias(hw);
hw.cmd('mwd a005006c a0050070 00000100');  % // Gain Treshold = 1, Gain < Treshold ? LD_ON ShutDown

%% CALIBRATE IR
[delayIR,delayIRsuccess,pixelVar]=Calibration.dataDelay.calibIRdelay(hw,dataDelayParams,runParams);
results.slowDelayCalibSuccess = delayIRsuccess;
results.delaySlowPixelVar = pixelVar;

% Metrics - edge width on one direction vs final image
[imU,~]=Calibration.dataDelay.getScanDirImgs(hw);
frameU.i = imU; frameU.z = imU; 
frame = hw.getFrame(10);
[~, metricsResults] = Validation.metrics.gridEdgeSharp(frame, []);
[~, metricsResultsU] = Validation.metrics.gridEdgeSharp(frameU, []);
fprintff('%s: UpImage=%2.2g, FinalImage=%2.2g.\n','horizSharpnessMean',metricsResultsU.horizMean,metricsResults.horizMean);
fprintff('%s: UpImage=%2.2g, FinalImage=%2.2g.\n','vertSharpnessMean',metricsResultsU.vertMean,metricsResults.vertMean);
fprintff('IR vertical pixel alignment variance [e=%g].\n',pixelVar);
results.horizEdge =  metricsResults.horizMean;
results.vertEdge =  metricsResults.vertMean;

%% CALIBRATE DEPTH
dataDelayParams.slowDelayInitVal = delayIR;
[delayZ,delayZsuccess]=Calibration.dataDelay.calibZdelay(hw,dataDelayParams,runParams);
results.fastDelayCalibSuccess = delayZsuccess;

%% SET REGISTERS
regs=Calibration.dataDelay.setAbsDelay(hw,delayZ,delayIR);

%% SET OLD VALUES
r.reset();
% setBias(hw,origBias);
hw.cmd('mwd a005006c a0050070 00000000');  % // Gain Treshold = 1, Gain < Treshold ? LD_ON ShutDown
end

function origBias = zeroBias(hw)
res = hw.cmd('irb e2 06 01');
origBias = res(end-1:end);
hw.cmd('iwb e2 06 01 00'); % Set laser bias to 0
end
function setBias(hw,value)
hw.cmd(['iwb e2 06 01 ',value]); % Set laser bias to value
end

