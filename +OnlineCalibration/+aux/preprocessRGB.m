function [rgbEdge, rgbIDT, rgbIDTx, rgbIDTy] = preprocessRGB(frame,params)
       
        
        [rgbEdge,~,~] = OnlineCalibration.aux.edgeSobelXY(uint8(frame.yuy2));
        [rgbIDT] = OnlineCalibration.aux.calcInverseDistanceImage(rgbEdge,params.inverseDistParams);% Ready for LibRealSenseImplementation
        rgbIDT = single(rgbIDT);
        [~,rgbIDTx,rgbIDTy] = OnlineCalibration.aux.edgeSobelXY(rgbIDT);
        
end
