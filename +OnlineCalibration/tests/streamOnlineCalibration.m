% This script captures frames from the connected unit and run the
% online calibration
clear

%% Parameters
depthRes = [480,640];
rgbRes = [1920,1080];
presetNum = 1;
hw = HWinterface;
hw.setPresetControlState(presetNum);
hw.startStream(0,depthRes,rgbRes);
hw.cmd('PIXEL_INVALIDATION_BYPASS 1');
[~,maxLP] = hw.cmd('irb e2 09 01 ');
hw.cmd(sprintf('iwb e2 0a 01 %x',maxLP));
cameraParams = OnlineCalibration.aux.getCameraParamsFromUnit(hw,rgbRes);
cameraParams.rgbRes = rgbRes;
cameraParams.depthRes = depthRes;

%% AC Params 
params = cameraParams;
[params.xAlpha,params.yBeta,params.zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(params.Rrgb);
params.cbGridSz = [9,13];% not part of the optimization 
[params] = OnlineCalibration.aux.getParamsForAC(params);

params.derivVar = 'P';
params.maxIters = 100;

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
iter = 1;
while true
    currTime = toc(startTime);
    currTmptr = hw.getLddTemperature;
    if ~(abs(currTmptr-prevTmptr) > flowParams.deltaTmptr || abs(currTime-prevTime) > flowParams.deltaTimeSec)
        continue;
    end
    params.iterFromStart = iter;
    [params,frame,CurrentOrigParams,validParams,dbg] = OnlineCalibration.aux.calcNewCameraParams(hw,params,originalParams,sectionMapDepth,sectionMapRgb,flowParams);
    
    if validParams
        prevTime = toc(startTime);
        prevTmptr = hw.getLddTemperature;
    else
        continue;
    end
    
    % Matlab uv mapping error visualization 
    tracker(iter).uvRMS = [OnlineCalibration.Metrics.calcUVMappingErr(frame,CurrentOrigParams,0),OnlineCalibration.Metrics.calcUVMappingErr(frame,params,0)];
    tracker(iter).score = [OnlineCalibration.aux.calculateCost(frame.vertices,frame.weights,frame.rgbIDT,CurrentOrigParams),OnlineCalibration.aux.calculateCost(frame.vertices,frame.weights,frame.rgbIDT,params)];
    tracker(iter).indices = [iter,iter+1];
    if 1
        figure(1);
        subplot(121);
        plot(reshape([tracker.indices]',2,[]),reshape([tracker.score]',2,[]),'-o'); title('Score'); xlabel('iterations'); 
        subplot(122);
        plot(reshape([tracker.indices]',2,[]),reshape([tracker.uvRMS]',2,[]),'-o'); title('UV RMS'); xlabel('iterations'); ylabel('pixels');
        drawnow;
        
        
        [uvMapOrig,~,~] = OnlineCalibration.aux.projectVToRGB(frame.vertices,CurrentOrigParams.rgbPmat,CurrentOrigParams.Krgb,CurrentOrigParams.rgbDistort);
        [uvMap,~,~] = OnlineCalibration.aux.projectVToRGB(frame.vertices,params.rgbPmat,params.Krgb,params.rgbDistort);
        improvedCost = scoreDiffPerVertex>0;
        
        figure(2);
        imagesc(frame.yuy2)
        hold on
        plot(uvMapOrig(:,1)+1,uvMapOrig(:,2)+1,'*r','markersize',1)
        plot(uvMap(:,1)+1,uvMap(:,2)+1,'*g','markersize',1)
        plot(uvMapOrig(improvedCost,1)+1,uvMapOrig(improvedCost,2)+1,'or','markersize',3)
        plot(uvMap(improvedCost,1)+1,uvMap(improvedCost,2)+1,'og','markersize',3)
        
        figure(3);
        imagesc(frame.rgbIDT)
        hold on
        plot(uvMapOrig(:,1)+1,uvMapOrig(:,2)+1,'*r','markersize',1)
        plot(uvMap(:,1)+1,uvMap(:,2)+1,'*g','markersize',1)
        plot(uvMapOrig(improvedCost,1)+1,uvMapOrig(improvedCost,2)+1,'or','markersize',3)
        plot(uvMap(improvedCost,1)+1,uvMap(improvedCost,2)+1,'og','markersize',3)
       
%         figure(3);
%         imagesc(frame.rgbIDT)
%         hold on
%         plot(uvMap(:,1)+1,uvMap(:,2)+1,'*r','markersize',1)
%         
        figure(4);
        subplot(121);
        imagesc(frame.i)
        hold on
        plot(frame.zEdgeSubPixel(:,:,2),frame.zEdgeSubPixel(:,:,1),'*r','markersize',1)
% 
        subplot(122);
        imagesc(frame.z/4)
        hold on
        plot(frame.zEdgeSubPixel(:,:,2),frame.zEdgeSubPixel(:,:,1),'*r','markersize',1)
        linkaxes;

        
        figure(5);
        imagesc(frame.rgbIDT);
        hold on;
        % plot(dbg.uvMap(:,1),dbg.uvMap(:,2),'*r','markersize',1)
        % plot(dbg.uvMapNew(:,1),dbg.uvMapNew(:,2),'*g','markersize',1)
        quiver(dbg.uvMap(:,1),dbg.uvMap(:,2),dbg.uvMapNew(:,1)-dbg.uvMap(:,1),dbg.uvMapNew(:,2)-dbg.uvMap(:,2),'r')

    end
    iter = iter + 1;
end

hw.stopStream;