function [validParams, hFactor, vFactor, newParams] = robotAc2Test_HW(dataPath, num, maxIters, burnToUnit, ignoreValidity, alternateIr)
    if ~exist('alternateIr', 'var')
        maxIters = false;
    end
    hFactor= -1;
    vFactor= -1;
    depthRes = [480,640];
    rgbRes = [1920,1080];
    presetNum = 1;
    hw = HWinterface;
    hw.setPresetControlState(presetNum);
    hw.startStream(0,depthRes,rgbRes);
    
    hw.cmd('AMCSET 5 64'); % Set laser gain to 100%
    hw.cmd('AMCSET 7 1');  % Set the invalidation bypass to 1
    if alternateIr
        hw.cmd('mwd a00e084c a00e0850 00000001')
    end
    cameraParams = OnlineCalibration.aux.getCameraParamsFromUnit(hw,rgbRes);
    cameraParams.rgbRes = rgbRes;
    cameraParams.depthRes = depthRes;
    
    %% AC Params
    params = cameraParams;
    [params.xAlpha,params.yBeta,params.zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(params.Rrgb);
    [params] = OnlineCalibration.aux.getParamsForAC(params);
    
    params.derivVar = 'P';
    if ~exist('maxIters', 'var')
        maxIters = 0;
    end
        params.maxIters = maxIters; %5

    if ~exist('burnToUnit', 'var')
        burnToUnit = False;
    end
    params.burnToUnit = burnToUnit; %true
    
    if ~exist('ignoreValidity', 'var')
        ignoreValidity = True;
    end
    params.ignoreValidity = ignoreValidity;
    
    flowParams.deltaTmptr = 0;
    flowParams.deltaTimeSec = 60*10;
    flowParams.pauseTimeAfterInvalidScene = 5;
    %% Online calibration flow
    startTime = tic;
    prevTime = toc(startTime);
    prevTmptr = hw.getLddTemperature;
    originalParams = params;
    sectionMapDepth = OnlineCalibration.aux.sectionPerPixel(params);
    sectionMapRgb = OnlineCalibration.aux.sectionPerPixel(params,1);
    
    
    % Stream is running
    currTime = toc(startTime);
    currTmptr = hw.getLddTemperature;
    params.iterFromStart = num;
    [newParams,frame,CurrentOrigParams,validParams,dbg] = OnlineCalibration.aux.calcNewCameraParams(hw,params,originalParams,sectionMapDepth,sectionMapRgb,flowParams, dataPath);
    try
        hFactor = dbg.acDataOut.hFactor;
        vFactor= dbg.acDataOut.vFactor;
    catch
        hFactor = nan;
        vFactor= nan;
    end
    hw.stopStream;
    if exist('dataPath', 'var') && exist('num', 'var')
        save(fullfile(dataPath, sprintf('%d_data.mat', num)) ,'newParams','params','frame','CurrentOrigParams','validParams','dbg','flowParams','originalParams','sectionMapDepth','sectionMapRgb','flowParams');
        save(fullfile(dataPath, sprintf('%d_dbg.mat', num)) ,'newParams','params','CurrentOrigParams','validParams','dbg','flowParams','originalParams','sectionMapDepth','sectionMapRgb','flowParams');
    end
end