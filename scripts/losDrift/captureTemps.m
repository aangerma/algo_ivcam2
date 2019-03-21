%% set regs to sperical / no filters
hw.setReg('RASTbiltBypass'     ,true);
hw.setReg('RASTbiltSharpnessR'     ,uint8(0));
hw.setReg('RASTbiltSharpnessS'     ,uint8(0));
hw.setReg('JFILbypass$'         ,false);
hw.setReg('JFILbilt1bypass'    ,true);
hw.setReg('JFILbilt2bypass'    ,true);
hw.setReg('JFILbilt3bypass'    ,true);
hw.setReg('JFILbiltIRbypass'   ,true);
hw.setReg('JFILdnnBypass'      ,true);
hw.setReg('JFILedge1bypassMode',uint8(1));
hw.setReg('JFILedge4bypassMode',uint8(1));
hw.setReg('JFILedge3bypassMode',uint8(1));
hw.setReg('JFILgeomBypass'     ,true);
hw.setReg('JFILgrad1bypass'    ,true);
hw.setReg('JFILgrad2bypass'    ,true);
hw.setReg('JFILirShadingBypass',true);
hw.setReg('JFILinnBypass'      ,true);
hw.setReg('JFILsort1bypassMode',uint8(1));
hw.setReg('JFILsort2bypassMode',uint8(1));
hw.setReg('JFILsort3bypassMode',uint8(1));
hw.setReg('JFILupscalexyBypass',true);
hw.setReg('JFILgammaBypass'    ,false);
hw.setReg('JFILgammaBypass'    ,false);
hw.setReg('JFILinvBypass',true);
hw.shadowUpdate();

dsmXscale=typecast(hw.read('EXTLdsmXscale'),'single');
dsmXoffset=typecast(hw.read('EXTLdsmXoffset'),'single');

%% capture world init

dummpyFrame = hw.getFrame(10);
initWorld = captureWorld(hw);

%% capture frames

reqTemps = [0];
%reqTemps = [35 45 55 65];

for ti=1:length(reqTemps)
    if (exist('tFrames','var') && length(tFrames) >= ti)
        continue;
    end
    
    t = reqTemps(ti);
    lddTemp = hw.getLddTemperature;
    while (lddTemp < t)
        frame = hw.getFrame(); figure(112); imagesc(frame.i);
        title(sprintf('Waiting for temperature to raise to %.2f, current: %.2f',...
            t, lddTemp));
        turnFilters(hw, true);
        pause(0.5);
        lddTemp = hw.getLddTemperature;
    end
    turnFilters(hw, false);

    % capture spherical
    hw.setReg('EXTLdsmXscale',dsmXscale*0.95);
    hw.setReg('EXTLdsmXoffset',dsmXoffset*1.05);
    hw.setReg('DIGGsphericalEn',true);
    hw.shadowUpdate();
    dummpyFrame = hw.getFrame();
    
    [tFrames{ti}, regsSph] = captureSpherical(hw, 500, 0.5, true);

    % capture world
    hw.setReg('EXTLdsmXscale',dsmXscale);
    hw.setReg('EXTLdsmXoffset',dsmXoffset);
    hw.setReg('DIGGsphericalEn',false);
    hw.shadowUpdate();
    dummpyFrame = hw.getFrame();

    tWorld{ti} = captureWorld(hw);
    
end

    