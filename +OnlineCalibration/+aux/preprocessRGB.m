function [rgbEdge, rgbIDT, rgbIDTx, rgbIDTy, sectionMapRgb, sectionMapRgbEdges] = preprocessRGB(frame,params)
       
        
        [rgbEdge,~,~] = OnlineCalibration.aux.edgeSobelXY(uint8(frame.yuy2));
%         rgbEdge(rgbEdge>10) = 10;
        if ~isfield(params.inverseDistParams,'norm')
            params.inverseDistParams.norm = 1;
        end
        if params.inverseDistParams.norm == 1
            [rgbIDT] = OnlineCalibration.aux.calcInverseDistanceImage(rgbEdge,params.inverseDistParams);% Ready for LibRealSenseImplementation
        else
            [rgbIDT] = OnlineCalibration.aux.calcInverseDistanceImage2(rgbEdge,params.inverseDistParams);% Ready for LibRealSenseImplementation
        end
        rgbIDT = single(rgbIDT);
        [~,rgbIDTx,rgbIDTy] = OnlineCalibration.aux.edgeSobelXY(rgbIDT);
        
        
        sectionMapRgb = vec(OnlineCalibration.aux.sectionPerPixel(params,1));
        % Section map per edge
        binEdgeIm = rgbEdge > params.gradRgbTh;
        sectionMapRgbEdges = sectionMapRgb(binEdgeIm);
end
