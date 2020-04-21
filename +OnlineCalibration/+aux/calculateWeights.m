function [weights,weightsT] = calculateWeights(frame,params)



    weights = frame.zEdgeSupressed(frame.zEdgeSupressed>0);
    edgesT = frame.zEdgeSupressed.';
    weightsT = edgesT(edgesT>0);
    
    weights = min(max(weights - params.gradZTh,0),params.gradZMax - params.gradZTh);
    weightsT = min(max(weightsT - params.gradZTh,0),params.gradZMax - params.gradZTh);

end