function [regs, results]=calibrate(hw, dataDelayParams, fprintff, runParams, calibParams, isFinalStage)

fResMirror = Calibration.aux.getMirrorFreq(hw);
fprintff('Mirror resonance frequency: %.1f\n', fResMirror);

results = struct('fastDelayCalibSuccess',[],'slowDelayCalibSuccess',[],'delaySlowPixelVar',[]);

warning('off','vision:calibrate:boardShouldBeAsymmetric');
sphericalScale = typecast(hw.read('sphericalscale'),'int16');
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
r.add('DIGGsphericalScale',int16(double(sphericalScale).*calibParams.dataDelay.sphericalScaleFactors));
r.set();

% origBias = zeroBias(hw);

%% CALIBRATE IR
[delayIR,delayIRsuccess,pixelVar]=Calibration.dataDelay.calibIRdelay(hw, dataDelayParams, runParams, calibParams, isFinalStage, fResMirror);
results.delayIR = delayIR;
results.slowDelayCalibSuccess = delayIRsuccess;
results.delaySlowPixelVar = pixelVar;

% Metrics - edge width on one direction vs final image
[imU,~]=Calibration.dataDelay.getScanDirImagesByLocTable(hw);
frameU.i = imU; frameU.z = imU; 
frame = hw.getFrame(10);
params.target.target = 'checkerboard_Iv2A1';
[~, metricsResults] = Validation.metrics.gridEdgeSharpIR(frame, params);
[~, metricsResultsU] = Validation.metrics.gridEdgeSharpIR(frameU, params);
fprintff('%s: UpImage=%2.2g, FinalImage=%2.2g.\n','horzWidthMeanAF',metricsResultsU.horzWidthMeanAF,metricsResults.horzWidthMeanAF);
fprintff('%s: UpImage=%2.2g, FinalImage=%2.2g.\n','vertWidthMeanAF',metricsResultsU.vertWidthMeanAF,metricsResults.vertWidthMeanAF);
fprintff('IR vertical pixel alignment variance [e=%g].\n',pixelVar);
results.horizEdge =  metricsResults.horzWidthMeanAF;
results.vertEdge =  metricsResults.vertWidthMeanAF;

%% CALIBRATE DEPTH
dataDelayParams.slowDelayInitVal = delayIR;
if calibParams.dataDelay.calibrateFast
    [delayZ,delayZsuccess]=Calibration.dataDelay.calibZdelay(hw, dataDelayParams, runParams, calibParams, isFinalStage, fResMirror);
else
    delayZsuccess = true;
    delayZ = delayIR;
end
results.delayZ = delayZ;
results.fastDelayCalibSuccess = delayZsuccess; %TODO: add delayZ and delayIR to results

%% SET REGISTERS
regs=Calibration.dataDelay.setAbsDelay(hw,delayZ,delayIR);

%% SET OLD VALUES
r.reset();
% setBias(hw,origBias);
end

function origBias = zeroBias(hw)
res = hw.cmd('irb e2 06 01');
origBias = res(end-1:end);
hw.cmd('iwb e2 06 01 00'); % Set laser bias to 0
end
function setBias(hw,value)
hw.cmd(['iwb e2 06 01 ',value]); % Set laser bias to value
end

