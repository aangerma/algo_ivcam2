function [params,frame,CurrentOrigParams,validParams,dbg] = calcNewCameraParams(hw,params,originalParams,sectionMapDepth,sectionMapRgb,flowParams)

loopCounter = 0;
while loopCounter <= params.maxIters 
    loopCounter = loopCounter + 1;
    
    frame = hw.getFrame(1,1,1);
    frame.yuy2Prev = hw.getColorFrame(1).color;
    frame.yuy2 = hw.getColorFrame(1).color;
    
    % Optimize parameters
    CurrentOrigParams = params;
    [frame.rgbEdge, frame.rgbIDT, frame.rgbIDTx, frame.rgbIDTy] = OnlineCalibration.aux.preprocessRGB(frame,params);
    [frame.irEdge] = OnlineCalibration.aux.preprocessIR(frame,params);
    [frame.zEdge,frame.zEdgeSupressed,frame.zEdgeSubPixel,frame.zValuesForSubEdges,frame.dirI] = OnlineCalibration.aux.preprocessZ(frame,params);
%     [frame.zEdge,frame.zEdgeSupressed,frame.zEdgeSubPixel,frame.zValuesForSubEdges,frame.dirI] = OnlineCalibration.aux.preprocessZAndIR(frame,params);
    frame.sectionMapDepth = sectionMapDepth(frame.zEdgeSupressed>0);
    frame.sectionMapRgb = sectionMapRgb(frame.rgbIDT>0);
    [frame.vertices] = OnlineCalibration.aux.subedges2vertices(frame,params);
    frame.weights = OnlineCalibration.aux.calculateWeights(frame,params);
    
    [validScene,~] = OnlineCalibration.aux.validScene(frame,params);
    if ~validScene
        fprintf('Invalid Scene... \n');
        pause(flowParams.pauseTimeAfterInvalidScene);
        continue;
    end
     
    newParams = OnlineCalibration.Opt.optimizeParameters(frame,params);
    % Output validity and update
    [validParams,params,dbg] = OnlineCalibration.aux.validOutputParameters(frame,params,newParams,originalParams,params.iterFromStart);
    if validParams
       return;
    end
end

end

