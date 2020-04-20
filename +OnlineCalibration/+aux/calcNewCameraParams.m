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
%     [frame.irEdge] = OnlineCalibration.aux.preprocessIR(frame,params);
%     [frame.zEdge,frame.zEdgeSupressed,frame.zEdgeSubPixel,frame.zValuesForSubEdges,frame.dirI] = OnlineCalibration.aux.preprocessZ(frame,params);    
    frame.sectionMapRgb = sectionMapRgb(frame.rgbIDT>0);
    [frame.irEdge,frame.zEdge,...
        frame.xim,frame.yim,frame.zValuesForSubEdges...
        ,frame.zGradInDirection,frame.dirPerPixel,frame.weights,frame.vertices,...
        frame.sectionMapDepth] = OnlineCalibration.aux.preprocessDepth(frame,params);
    
    
    [validScene,~] = OnlineCalibration.aux.validScene(frame,params);
    if ~validScene
        fprintf('Invalid Scene... \n');
        pause(flowParams.pauseTimeAfterInvalidScene);
        continue;
    end
    switch params.derivVar
        case 'KrgbRT'
            newParams = OnlineCalibration.Opt.optimizeParameters(frame,params);
        case 'P'
            newParams = OnlineCalibration.Opt.optimizeParametersP(frame,params);
        case 'KdepthRT'
            newParams = OnlineCalibration.Opt.optimizeParametersKdepthRT(frame,params);
        otherwise
            error('No such optimization option!');
    end
    % Output validity and update
    [validParams,params,dbg] = OnlineCalibration.aux.validOutputParameters(frame,params,newParams,originalParams,params.iterFromStart);
    if validParams
       return;
    end
end

end

