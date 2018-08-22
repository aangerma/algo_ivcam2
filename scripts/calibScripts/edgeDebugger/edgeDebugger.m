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