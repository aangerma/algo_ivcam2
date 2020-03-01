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
cameraParams = OnlineCalibration.aux.getCameraParamsFromUnit(hw);
cameraParams.rgbRes = rgbRes;
cameraParams.depthRes = depthRes;

%% AC Params 
params = cameraParams;
params.cbGridSz = [9,13];% not part of the optimization 
params.inverseDistParams.alpha = 1/3;
params.inverseDistParams.gamma = 0.98;
params.inverseDistParams.metric = 1; % Metrics norm. Currently only suppotrs L1. Should support L2.
params.gradITh = 3.5; % Ignore pixels with IR grad of less than this
params.gradZTh = 25; % Ignore pixels with Z grad of less than this
params.gradZMax = 1000; 
params.derivVar = 'P';
params.maxStepSize = 1;%1;
params.tau = 0.5;
params.controlParam = 0.5;
params.minStepSize = 1e-5;
params.maxBackTrackIters = 50;
params.minRgbPmatDelta = 1e-5;
params.minCostDelta = 1;
params.maxOptimizationIters = 50;
params.zeroLastLineOfPGrad = 1;
% params.rgbPmatNormalizationMat = [0.3242,     0.4501,    0.2403,   359.3750;      0.3643,     0.5074      0.2689     402.3438;      0.0029     0.0040     0.0021     3.2043];
params.rgbPmatNormalizationMat = [0.35682896, 0.26685065,1.0236474,0.00068233482; 0.35521242, 0.26610452, 1.0225836, 0.00068178622; 410.60049, 318.23358, 1205.4570, 0.80363423];
params.edgeThresh4logicIm = 0.1;
params.seSize = 3;
params.moveThreshPixVal = 20;
params.moveThreshPixNum =  3e-05*prod(params.rgbRes);
params.moveGaussSigma = 1;
params.maxXYMovementPerIteration = [10,2,2];
params.maxXYMovementFromOrigin = 20;
params.numSectionsV = 2;
params.numSectionsH = 2;
params.edgeDistributMinMaxRatio = 0.005;
params.minWeightedEdgePerSectionDepth = 3000;
params.minWeightedEdgePerSectionRgb = 300000;


flowParams.deltaTmptr = 3;
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
    if ~(abs(currTmptr-prevTime) > flowParams.deltaTmptr || abs(currTime-prevTime) > flowParams.deltaTimeSec)
        continue;
    end
    
    % specialFrameRequest()
    frame = hw.getFrame(1,1,1);
    frame.yuy2Prev = hw.getColorFrame(1).color;
    frame.yuy2 = hw.getColorFrame(1).color;
    
    
    
    % Optimize parameters
    origParams = params;
    [frame.rgbEdge, frame.rgbIDT, frame.rgbIDTx, frame.rgbIDTy] = OnlineCalibration.aux.preprocessRGB(frame,params);
    [frame.irEdge] = OnlineCalibration.aux.preprocessIR(frame,params);
    [frame.zEdge,frame.zEdgeSupressed,frame.zEdgeSubPixel,frame.zValuesForSubEdges] = OnlineCalibration.aux.preprocessZ(frame,params);
    frame.sectionMapDepth = sectionMapDepth(frame.zEdgeSupressed>0);
    frame.sectionMapRgb = sectionMapRgb(frame.rgbIDT>0);
    [frame.vertices] = OnlineCalibration.aux.subedges2vertices(frame,params);
    frame.weights = OnlineCalibration.aux.calculateWeights(frame,params);
    
    if ~OnlineCalibration.aux.validScene(frame,params)
        fprintf('Invalid Scene... \n');
        pause(flowParams.pauseTimeAfterInvalidScene);
        continue;
    end
    
    
    
    newParams = OnlineCalibration.Opt.optimizeParameters(frame,params);
    
    
    
    
    
    % Output validity and update
    [validParams,params,dbg] = OnlineCalibration.aux.validOutputParameters(frame,params,newParams,originalParams,iter);
    if validParams
        prevTime = toc(startTime);
        prevTmptr = hw.getLddTemperature;
    else
        continue;
    end
    
    % Matlab uv mapping error visualization 
    scoreDiffPerRegion = dbg.scoreDiffPerRegion;
    scoreDiffPerVertex = dbg.scoreDiffPerVertex;
    tracker(iter).uvRMS = [OnlineCalibration.Metrics.calcUVMappingErr(frame,origParams,0),OnlineCalibration.Metrics.calcUVMappingErr(frame,params,0)];
    tracker(iter).score = [OnlineCalibration.aux.calculateCost(frame.vertices,frame.weights,frame.rgbIDT,origParams),OnlineCalibration.aux.calculateCost(frame.vertices,frame.weights,frame.rgbIDT,params)];
    tracker(iter).indices = [iter,iter+1];
    if 1
        figure(1);
        subplot(121);
        plot(reshape([tracker.indices]',2,[]),reshape([tracker.score]',2,[]),'-o'); title('Score'); xlabel('iterations'); 
        subplot(122);
        plot(reshape([tracker.indices]',2,[]),reshape([tracker.uvRMS]',2,[]),'-o'); title('UV RMS'); xlabel('iterations'); ylabel('pixels');
        drawnow;
        
        
        [uvMapOrig,~,~] = OnlineCalibration.aux.projectVToRGB(frame.vertices,origParams.rgbPmat,origParams.Krgb,origParams.rgbDistort);
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

    end
    iter = iter + 1;
end
