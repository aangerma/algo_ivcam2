function [v,xim,yim] = updateVerticesWithNewDSM(v,regs,dsmRegs,newDsmRegs,kdepth)

    % Update CB vertices
    zValsCB = v(:,3);
    v(:,1:2) = -v(:,1:2);
    los = OnlineCalibration.K2DSM.ConvertNormVerticesToLos(regs, dsmRegs, v);
    v = OnlineCalibration.K2DSM.ConvertLosToNormVertices(regs, newDsmRegs, los);
    v = v./v(:,3).*zValsCB;
    v(:,1:2) = -v(:,1:2);

    
    xy = v*kdepth';
    xim = xy(:,1)./xy(:,3);
    yim = xy(:,2)./xy(:,3);
end

