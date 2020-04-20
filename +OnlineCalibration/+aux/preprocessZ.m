function [zEdge,zEdgeSupressed,zEdgeSubPixel,zValuesForSubEdges,dirI] = preprocessZ(frame,params)

    [zEdge,Zx,Zy] = OnlineCalibration.aux.edgeSobelXY(uint16(frame.z));
    validEdgePixels = frame.irEdge>params.gradITh & zEdge>params.gradZTh; 
    
    sz = size(frame.z); 
    [gridX,gridY] = meshgrid(1:sz(2),1:sz(1)); % gridX/Y contains the indices of the pixels
    directionInDeg = mod(atan2d(Zy,Zx),180);% For each pixel, we can calculate the direction of the gradient in degrees
    [~,dirI] = min(abs(directionInDeg - reshape([0,45,90,135],1,1,[])),[],3); % Quantize the direction to 4 directions (don't care about the sign)
    dirsVec = [0,1; 1,1; 1,0; 1,-1]; % These are the 4 directions

    zEdgeSupressed = zeros(sz);
    zEdgeSubPixel = zeros([sz,2]);
    zValuesForSubEdges = zeros(sz);
    for d = 1:size(dirsVec,1)% Do it for every direction
        currDir= dirsVec(d,:);
        zEdge_plus = circshift(zEdge,-currDir); 
        zEdge_minus = circshift(zEdge,+currDir);
        % The pixels which are considered edges in direction d 
        supressedEdges_d = validEdgePixels & dirI == d & (zEdge >= zEdge_plus) & (zEdge >= zEdge_minus);
        % Calculated the sub pixel location of the edge
        fraqStep = (-0.5*(zEdge_plus-zEdge_minus)./(zEdge_plus+zEdge_minus-2*zEdge)); % The step we need to move to reach the subpixel gradient i nthe gradient direction
        subGrad_d = fraqStep.*reshape(currDir,1,1,[]);
        subGrad_d = subGrad_d + cat(3,gridY,gridX);% the location of the subpixel gradient

        zEdgeSupressed(supressedEdges_d) = zEdge(supressedEdges_d);
        zEdgeSubPixel(cat(3,supressedEdges_d,supressedEdges_d)) = subGrad_d(cat(3,supressedEdges_d,supressedEdges_d));
        
        % Take the z value of the close part of the edge
        Z_plus = circshift(frame.z,-currDir);
        Z_minus = circshift(frame.z,+currDir);
        Z_closest = min(Z_plus,Z_minus);
        zValuesForSubEdges(supressedEdges_d) = Z_closest(supressedEdges_d);
    end
    
    
end
