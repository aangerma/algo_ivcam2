function [ delayRes ] = validateDelays( hw, calibParams, fprintff)
delayRes = [];
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


%% IR Delay 
[d,~,pixVar]=Calibration.dataDelay.calcIRDelayFix(hw);
if (isnan(d))%CB was not found, throw delay forward to find a good location
    d = 3000;
end
delayRes.DelaySlowOffest = abs(d);
delayRes.DelaySlowPixVar = pixVar;

fprintff('IR nano seconds diff: %d.\n',abs(d));


%% Depth Delay
[~,saveVal] = hw.cmd('irb e2 06 01'); % Original Laser Bias
hw.cmd('iwb e2 06 01 00'); % set Laser Bias to 0
hw.setReg('DESTaltIrEn', true);

imB=double(hw.getFrame(30).i)/255;
[d,~]=Calibration.dataDelay.calcZDelayFix(hw,imB);
if (isnan(d))%CB was not found, throw delay forward to find a good location
    d = 3000;
end
delayRes.DelayFastOffest = abs(d);

fprintff('Depth nano seconds diff: %d.\n',abs(d));

hw.setReg('DESTaltIrEn', false);
hw.cmd(sprintf('iwb e2 06 01 %02x',saveVal)); %reset value

r.reset();
end

