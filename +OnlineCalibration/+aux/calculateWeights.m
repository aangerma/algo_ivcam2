function [weights] = calculateWeights(frame,params)

    weights = sampleByMask(frame.zEdgeSupressed,frame.zEdgeSupressed>0);
   
    weights = min(max(weights - params.gradZTh,0),params.gradZMax - params.gradZTh);
       

end