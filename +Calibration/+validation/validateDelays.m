function [ delayRes, frames] = validateDelays( hw, calibParams, fprintff)
delayRes = [];
frames = struct('z',[],'i',[]);
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
r.add('JFILgammaBypass'    ,false    );
r.add('DIGGsphericalEn'    ,true     );
r.add('DIGGnotchBypass'    ,true     );
r.add('DESTaltIrEn'        ,false    );
r.set();


%% IR Delay 
delay = 0;
val_mode = true;
[~, d,imIR,pixVar] = Calibration.dataDelay.IR_DelayCalib(hw,delay ,calibParams,val_mode);
if (isnan(d))%CB was not found, throw delay forward to find a good location
    d = 3000;
end
delayRes.DelaySlowOffest = abs(d);
delayRes.DelaySlowPixVar = pixVar;
frames(1).i = uint16(imIR(:,:,1));
frames(2).i = uint16(imIR(:,:,1));

fprintff('IR nano seconds diff: %d.\n',abs(d));


%% Depth Delay
[~,saveVal] = hw.cmd('irb e2 06 01'); % Original Laser Bias
hw.cmd('iwb e2 06 01 00'); % set Laser Bias to 0
hw.setReg('DESTaltIrEn', true);

imB=double(hw.getFrame(30).i)/255;
[d,imZ]=Calibration.dataDelay.calcZDelayFix(hw,imB);
if (isnan(d))%CB was not found, throw delay forward to find a good location
    d = 3000;
end
delayRes.DelayFastOffest = abs(d);
frames(1).z = uint16(imZ(:,:,1));
frames(2).z = uint16(imZ(:,:,1));
fprintff('Depth nano seconds diff: %d.\n',abs(d));

hw.setReg('DESTaltIrEn', false);
hw.cmd(sprintf('iwb e2 06 01 %02x',saveVal)); %reset value

r.reset();
end

