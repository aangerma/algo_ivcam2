function [zEdge,zEdgeSupressed,zEdgeSubPixel,zValuesForSubEdges,iEdgeDirI] = preprocessZAndIR(frame,params)

    [zEdge,Zx,Zy] = OnlineCalibration.aux.edgeSobelXY(uint16(frame.z));
    [iEdge,Ix,Iy] = OnlineCalibration.aux.edgeSobelXY(uint16(frame.i));
    validEdgePixels = iEdge>params.gradITh & zEdge>params.gradZTh; 
    
    [iEdgeSupressed,iEdgeSubPixel,iValuesForSubEdges,iEdgeDirI] = subpixelEdges(frame.i,iEdge,Ix,Iy,validEdgePixels);
    [zEdgeSupressed,zEdgeSubPixel,zValuesForSubEdges,zEdgeDirI] = subpixelEdgesWithIRRefinement(frame.z,zEdge,Zx,Zy,validEdgePixels,iEdgeSubPixel,iEdgeDirI,frame.i);
    
    
    
end

function [edgeSupressed,edgeSubPixel,valuesForSubEdges,dirI] = subpixelEdges(I,iEdge,Ix,Iy,validEdgePixels)

    sz = size(I); 
    [gridX,gridY] = meshgrid(1:sz(2),1:sz(1)); % gridX/Y contains the indices of the pixels
    directionInDeg = mod(atan2d(Iy,Ix),180);% For each pixel, we can calculate the direction of the gradient in degrees
    [~,dirI] = min(abs(directionInDeg - reshape([0,45,90,135],1,1,[])),[],3); % Quantize the direction to 4 directions (don't care about the sign)
    dirsVec = [0,1; 1,1; 1,0; 1,-1]; % These are the 4 directions

    edgeSupressed = zeros(sz);
    edgeSubPixel = zeros([sz,2]);
    valuesForSubEdges = zeros(sz);
    for d = 1:size(dirsVec,1)% Do it for every direction
        currDir= dirsVec(d,:);
        edge_plus = circshift(iEdge,-currDir); 
        edge_minus = circshift(iEdge,+currDir);
        % The pixels which are considered edges in direction d 
        supressedEdges_d = validEdgePixels & dirI == d & (iEdge >= edge_plus) & (iEdge >= edge_minus);
        % Calculated the sub pixel location of the edge
         
        fraqStep = (-0.5*(edge_plus-edge_minus)./(edge_plus+edge_minus-2*iEdge)); % The step we need to move to reach the subpixel gradient i nthe gradient direction
        fraqStep((edge_plus+edge_minus-2*iEdge)==0) = 0;
        subGrad_d = fraqStep.*reshape(currDir,1,1,[]);
        subGrad_d = subGrad_d + cat(3,gridY,gridX);% the location of the subpixel gradient

        edgeSupressed(supressedEdges_d) = iEdge(supressedEdges_d);
        edgeSubPixel(cat(3,supressedEdges_d,supressedEdges_d)) = subGrad_d(cat(3,supressedEdges_d,supressedEdges_d));
        
        % Take the z value of the close part of the edge
        I_plus = circshift(I,-currDir);
        I_minus = circshift(I,+currDir);
        I_closest = min(I_plus,I_minus);
        valuesForSubEdges(supressedEdges_d) = I_closest(supressedEdges_d);
    end
end
function [edgeSupressed,edgeSubPixel,valuesForSubEdges,dirI] = subpixelEdgesWithIRRefinement(I,iEdge,Ix,Iy,validEdgePixels,irSubEdges,irDirI,IR)

    sz = size(I); 
    [gridX,gridY] = meshgrid(1:sz(2),1:sz(1)); % gridX/Y contains the indices of the pixels
    directionInDeg = atan2d(Iy,Ix);% For each pixel, we can calculate the direction of the gradient in degrees
    directionInDeg(directionInDeg<0) = directionInDeg(directionInDeg<0) + 360;
    [~,dirI] = min(abs(directionInDeg - reshape([0,45,90,135,180,225,270,315],1,1,[])),[],3); % Quantize the direction to 4 directions (don't care about the sign)
    dirsVec = [0,1; 1,1; 1,0; 1,-1]; % These are the 4 directions
    dirsVec = [dirsVec;-dirsVec];
    
    edgeSupressed = zeros(sz);
    edgeSubPixel = zeros([sz,2]);
    valuesForSubEdges = zeros(sz);
    for d = 1:size(dirsVec,1)% Do it for every direction
        currDir= dirsVec(d,:);
        edge_plus = circshift(iEdge,-currDir); 
        edge_minus = circshift(iEdge,+currDir);
        IR_plus = circshift(IR,-currDir); 
        IR_minus = circshift(IR,+currDir);
        
        % The pixels which are considered edges in direction d 
        supressedEdges_d = validEdgePixels & dirI == d & (iEdge >= edge_plus) & (iEdge >= edge_minus);
        % Calculated the sub pixel location of the edge
        fraqStep = (-0.5*(edge_plus-edge_minus)./(edge_plus+edge_minus-2*iEdge)); % The step we need to move to reach the subpixel gradient i nthe gradient direction
        subGrad_d = fraqStep.*reshape(currDir,1,1,[]);
        subGrad_d = subGrad_d + cat(3,gridY,gridX);% the location of the subpixel gradient
    
        irEdgePossibleLocationSamePixel = irSubEdges(:,:,1) > 0 & supressedEdges_d;
        circIRSubEdgesMinus = circshift(irSubEdges,currDir);
        circIRSubEdgesPlus = circshift(irSubEdges,-currDir);
        irEdgeValidLocationAdjPixel = ((IR_plus>IR_minus).*circIRSubEdgesPlus(:,:,1) | (IR_plus<IR_minus).*circIRSubEdgesMinus(:,:,1)) & supressedEdges_d & ~irEdgePossibleLocationSamePixel;
        irEdgeLocationAdjPixelX = (IR_plus>IR_minus).*circIRSubEdgesPlus(:,:,1) + (IR_plus<IR_minus).*circIRSubEdgesMinus(:,:,1);
        irEdgeLocationAdjPixelY = (IR_plus>IR_minus).*circIRSubEdgesPlus(:,:,2) + (IR_plus<IR_minus).*circIRSubEdgesMinus(:,:,2);
        irEdgeLocationAdj =cat(3,irEdgeLocationAdjPixelX,irEdgeLocationAdjPixelY);
        
        irEdgePossibleLocationAdjPixel = circIRSubEdgesMinus(:,:,1) > 0 & supressedEdges_d & ~irEdgePossibleLocationSamePixel;
        
        
        edgeSubPixel(cat(3,supressedEdges_d,supressedEdges_d)) = subGrad_d(cat(3,supressedEdges_d,supressedEdges_d));
        edgeSubPixel(cat(3,irEdgeValidLocationAdjPixel,irEdgeValidLocationAdjPixel)) = irEdgeLocationAdj(cat(3,irEdgeValidLocationAdjPixel,irEdgeValidLocationAdjPixel));
        edgeSubPixel(cat(3,irEdgePossibleLocationSamePixel,irEdgePossibleLocationSamePixel)) = irSubEdges(cat(3,irEdgePossibleLocationSamePixel,irEdgePossibleLocationSamePixel));
        ix4All = edgeSubPixel(:,:,1)>0;
        edgeSupressed(ix4All) = iEdge(ix4All);
        
        
        
        % Take the z value of the close part of the edge
        I_plus = circshift(I,-currDir);
        I_minus = circshift(I,+currDir);
        I_closest = min(I_plus,I_minus);
        valuesForSubEdges(ix4All) = I_closest(ix4All);
    end
end
