function [regs,delayZsuccess,delayIRsuccess]=calibrate(hw,dataDelayParams,verbose)


warning('off','vision:calibrate:boardShouldBeAsymmetric');

%% SET
calibconfig       =struct('name','RASTbiltBypass'     ,'val',true     );
calibconfig(end+1)=struct('name','JFILbypass$'        ,'val',false    );
calibconfig(end+1)=struct('name','JFILbilt1bypass'    ,'val',true     );
calibconfig(end+1)=struct('name','JFILbilt2bypass'    ,'val',true     );
calibconfig(end+1)=struct('name','JFILbilt3bypass'    ,'val',true     );
calibconfig(end+1)=struct('name','JFILbiltIRbypass'   ,'val',true     );
calibconfig(end+1)=struct('name','JFILdnnBypass'      ,'val',true     );
calibconfig(end+1)=struct('name','JFILedge1bypassMode','val',uint8(1) );
calibconfig(end+1)=struct('name','JFILedge4bypassMode','val',uint8(1) );
calibconfig(end+1)=struct('name','JFILedge3bypassMode','val',uint8(1) );
calibconfig(end+1)=struct('name','JFILgeomBypass'     ,'val',true     );
calibconfig(end+1)=struct('name','JFILgrad1bypass'    ,'val',true     );
calibconfig(end+1)=struct('name','JFILgrad2bypass'    ,'val',true     );
calibconfig(end+1)=struct('name','JFILirShadingBypass','val',true     );
calibconfig(end+1)=struct('name','JFILinnBypass'      ,'val',true     );
calibconfig(end+1)=struct('name','JFILsort1bypassMode','val',uint8(1) );
calibconfig(end+1)=struct('name','JFILsort2bypassMode','val',uint8(1) );
calibconfig(end+1)=struct('name','JFILsort3bypassMode','val',uint8(1) );
calibconfig(end+1)=struct('name','JFILupscalexyBypass','val',true     );
calibconfig(end+1)=struct('name','JFILgammaBypass'    ,'val',false    );
calibconfig(end+1)=struct('name','DIGGsphericalEn'    ,'val',true     );
calibconfig(end+1)=struct('name','DIGGnotchBypass'    ,'val',true     );
calibconfig(end+1)=struct('name','DESTaltIrEn'        ,'val',false );

%% GET OLD VALUES
for i=1:length(calibconfig)
    calibconfig(i).oldval=hw.read(calibconfig(i).name );%exact name
end

%% SET CALIB VALUES
for i=1:length(calibconfig)
    hw.setReg(calibconfig(i).name    ,calibconfig(i).val,true);
end
hw.shadowUpdate();

%% CALIBRATE IR
[delayIR,delayIRsuccess]=Calibration.dataDelay.calibIRdelay(hw,dataDelayParams,verbose);

%% CALIBRATE DEPTH
dataDelayParams.slowDelayInitVal = delayIR;
[delayZ,delayZsuccess]=Calibration.dataDelay.calibZdelay(hw,dataDelayParams,verbose);

%% SET REGISTERS
regs=Calibration.dataDelay.setAbsDelay(hw,delayZ,delayIR);

%% SET OLD VALUES
for i=1:length(calibconfig)
    hw.setReg(calibconfig(i).name    ,calibconfig(i).oldval);
end

end




