function [regs, results]=calibrate(hw,dataDelayParams,verbose)

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


%% CALIBRATE IR
[delayIR,delayIRsuccess,pixelVar]=Calibration.dataDelay.calibIRdelay(hw,dataDelayParams,verbose);
results.slowDelayCalibSuccess = delayIRsuccess;
results.delaySlowPixelVar = pixelVar;

%% CALIBRATE DEPTH
dataDelayParams.slowDelayInitVal = delayIR;
[delayZ,delayZsuccess]=Calibration.dataDelay.calibZdelay(hw,dataDelayParams,verbose);
results.fastDelayCalibSuccess = delayZsuccess;

%% SET REGISTERS
regs=Calibration.dataDelay.setAbsDelay(hw,delayZ,delayIR);

%% SET OLD VALUES
r.reset();
end




