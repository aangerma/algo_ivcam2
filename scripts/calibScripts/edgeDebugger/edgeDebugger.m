% calibrate DSM if unit did not pass algo calib
calibrateCoarseDSM = 0;

getEdgeMetric = 1;

% Connect matlab to device
hw = HWinterface();
% Let it work for a second so it will be stable.
hw.getFrame(30);
% Calibrate DSM Coarse
if calibrateCoarseDSM
    [~] = calibCoarseDSM(hw);
end
% Config unit to mode where there is almost no post processing 
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
if getEdgeMetric
    % Get Up and bottom image
    [frameU.i,frameD.i] = getScanDirImgs(hw,30);
    
    tabplot; imagesc(frameU.i); title('Up Image'); colorbar;
    tabplot; imagesc(frameD.i); title('Down Image'); colorbar;
    frameU.z = frameU.i; 
    frameD.z = frameD.i; 
    [~, metricsResultsU] = Validation.metrics.gridEdgeSharp(frameU, []);
    [~, metricsResultsD] = Validation.metrics.gridEdgeSharp(frameD, []);
    
    fprintf('%s: UpImage=%2.2g, DownImage=%2.2g.\n','horizSharpnessMean',metricsResultsU.horizMean,metricsResultsD.horizMean);
    fprintf('%s: UpImage=%2.2g, DownImage=%2.2g.\n','vertSharpnessMean',metricsResultsU.vertMean,metricsResultsD.vertMean);
    fprintf('%s: UpImage=%2.2g, DownImage=%2.2g.\n','contrastMean',metricsResultsU.contMean,metricsResultsD.contMean);

end
r.reset();


%% Look at different APD values
frame = hw.getFrame(30); tabplot; imagesc(frame.i);
calibParams = xml2structWrapper('C:\source\algo_ivcam2\Tools\CalibTools\IV2calibTool\calibParams.xml');
for i = 0:500:3000
    newVal = dec2hex( ( round(hex2dec('1400')+i)/2)*2+1 );
    Calibration.dataDelay.setAbsDelay(hw,[],calibParams.dataDelay.slowDelayInitVal);
    hw.cmd(['mwd a0040084 a0040088 0000', newVal]);
    frame = hw.getFrame(30); tabplot; imagesc(frame.i);
    [p,bsz] = detectCheckerboardPoints(normByMax(double(frame.i)));
    title(newVal);
    [delayRegs,okZ,okIR]=Calibration.dataDelay.calibrate(hw,calibParams.dataDelay,1);
    fprintf('APD Val = %s, OkZ%d, okIR=%d.\n',newVal,okZ,okIR);
end

hw.cmd('mwd a0040084 a0040088 00001400');
frame = hw.getFrame(30); tabplot; imagesc(frame.i);
%% Look at different Laser Powers 
%{
In case you want to lower to LDD power, you need to write the following commands – 
	Read the initial values (to write them at the end of the process) – 
        irb e2 03 01
        irb e2 08 01 
	Write new values – 
        iwb e2 03 01 10 
        iwb e2 08 01 00 // lower value is 00 (not 0mA), higher value is a4 (240mA)

%}
origMode = hw.cmd('irb e2 03 01');origMode = origMode(end-1:end);
origModulation = hw.cmd('irb e2 08 01'); origModulation = origModulation(end-1:end);
origLaserBias = hw.cmd('irb e2 06 01'); origLaserBias = origLaserBias(end-1:end);

hw.cmd('iwb e2 03 01 10'); % Overide current laser configuration
frame = hw.getFrame(30); tabplot; imagesc(frame.i);
for i = fliplr(0:16:176)
    newVal = dec2hex( i );
    
    hw.cmd(['iwb e2 08 01 ', newVal]);
    frame = hw.getFrame(30); tabplot; imagesc(frame.i);
    title(newVal);
    [~,okZ,okIR]=Calibration.dataDelay.calibrate(hw,calibParams.dataDelay,1);
   
    fprintf('[] okIR[e=%g] okZ[e=%g]\n',okIR,okZ);
    
end
%% Calibrate
calibParams = xml2structWrapper('C:\source\algo_ivcam2\Tools\CalibTools\IV2calibTool\calibParams.xml');
[delayRegs,okZ,okIR]=Calibration.dataDelay.calibrate(hw,calibParams.dataDelay,1);
results.delayS=(1-okIR);
results.delayF=(1-okZ);
if(okIR)
    fprintf('[v] ir calib passed[e=%g]\n',results.delayS);
else
    fprintf('[x] ir calib failed[e=%g]\n',results.delayS);
end