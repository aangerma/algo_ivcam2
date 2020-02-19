function [irEdge] = preprocessIR(frame,params)
        [irEdge,~,~] = OnlineCalibration.aux.edgeSobelXY(uint8(frame.i));
end
