
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
hw.setReg('DIGGsphericalEn',true);
hw.shadowUpdate();

%% reduce x fov
dsmXscale=typecast(hw.read('EXTLdsmXscale'),'single');
dsmXoffset=typecast(hw.read('EXTLdsmXoffset'),'single');

hw.setReg('EXTLdsmXscale',dsmXscale*0.95);
hw.setReg('EXTLdsmXoffset',dsmXoffset*1.03);

%% capture frames

%nFrames = 10;
%delay = 0.1;

timeInMin = 20;
timeInSec = timeInMin*60;
delay = 0.6;
nFrames = timeInSec / delay;
delay = 0;

clear frames;
clear temps;
verbose= true;
tic;
for i = 1:nFrames
    frames(i) = hw.getFrame();
    %frames(i).i = fillInternalHolesMM(frames(i).i);
    [temps(i).ldd,temps(i).mctemps(i).ma,temps(i).tSense,temps(i).vSense]=hw.getLddTemperature;
    frameTime(i) = toc;
    if (delay ~= 0)
        pause(delay);
    end
    if (verbose)
        figure(171); imagesc(frames(i).i); title(sprintf('frame %g of %g, time: %g', i, nFrames, toc));
    end
end

for i = 1:length(frames)
    frames(i).i = fillInternalHolesMM(frames(i).i);
end 

params = Validation.aux.defaultMetricsParams();
[score, results] = Validation.metrics.losLaserFOVDrift(frames, params);

[score, results] = Validation.metrics.losGridDrift(frames, params);

ir = frames(1).i;
[pts, gridSize] = Validation.aux.findCheckerboard(ir);
figure; imagesc(ir); hold on; plot(pts(:,1),pts(:,2),'+r');

