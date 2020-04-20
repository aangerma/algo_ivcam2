function [iEdge,zEdge,xim,yim,zValuesForSubEdges,zGradInDirection,directionIndex,weights,vertices,sectionMapDepth] = preprocessDepth(frame,params)

    % Get gradient direction in IR
    % Calculate sub pixel location in IR
    % The Z value should be the minimal value accross 4  to the darker side of
    % the edge. Take a 1x4 enviroment. The asymetry should be so the the dark
    % side gets the additional pixel
    % Calculate the gradient in Z along this direction - Invalidate points
    % by the gradient in Z along this direction  
%     
    [zEdge,Zx,Zy] = OnlineCalibration.aux.edgeSobelXY(uint16(frame.z),2);
    [iEdge,Ix,Iy] = OnlineCalibration.aux.edgeSobelXY(uint16(frame.i),2);
    validEdgePixelsByIR = iEdge>params.gradITh; 
    
    sz = size(frame.i);
    [gridX,gridY] = meshgrid(1:sz(2),1:sz(1)); % gridX/Y contains the indices of the pixels
    sectionMapDepth = OnlineCalibration.aux.sectionPerPixel(params);

    locRC = [gridY(validEdgePixelsByIR),gridX(validEdgePixelsByIR)];
    sectionMapValid = sectionMapDepth(validEdgePixelsByIR);
    IxValid = Ix(validEdgePixelsByIR);
    IyValid = Iy(validEdgePixelsByIR);
    directionInDeg = atan2d(IyValid,IxValid);
    directionInDeg(directionInDeg<0) = directionInDeg(directionInDeg<0) + 360;
    [~,directionIndex] = min(abs(directionInDeg - [0:45:315]),[],2); % Quantize the direction to 4 directions (don't care about the sign)
    dirsVec = [0,1; 1,1; 1,0; 1,-1]; % These are the 4 directions
    dirsVec = [dirsVec;-dirsVec];

    
    if 1
        % Take the right direction
        dirPerPixel = dirsVec(directionIndex,:);
        localRegion = locRC + dirPerPixel.*reshape(vec(-2:1),1,1,[]);
        localEdges = squeeze(interp2(iEdge,localRegion(:,2,:),localRegion(:,1,:)));
        isSupressed = localEdges(:,3) >= localEdges(:,2) & localEdges(:,3) >= localEdges(:,4);

        fraqStep = (-0.5*(localEdges(:,4)-localEdges(:,2))./(localEdges(:,4)+localEdges(:,2)-2*localEdges(:,3))); % The step we need to move to reach the subpixel gradient i nthe gradient direction
        fraqStep((localEdges(:,4)+localEdges(:,2)-2*localEdges(:,3))==0) = 0;

        locRCsub = locRC + fraqStep.*dirPerPixel;

        % Calculate the Z gradient for thresholding
        localZx = squeeze(interp2(Zx,localRegion(:,2,2:3),localRegion(:,1,2:3)));
        localZy = squeeze(interp2(Zy,localRegion(:,2,2:3),localRegion(:,1,2:3)));
        zGrad = [mean(localZy,2) ,mean(localZx,2)];
        zGradInDirection = abs(sum(zGrad.*normr(dirPerPixel),2));
        % Take the z value of the closest part of the edge
        localZvalues = squeeze(interp2(frame.z,localRegion(:,2,:),localRegion(:,1,:)));
        
        zValuesForSubEdges = min(localZvalues,[],2);
        edgeSubPixel = fliplr(locRCsub);% From Row-Col to XY
    else
        [edgeSubPixel,zValues,zGradInDirection] = subEdgesByForLoop(iEdge,frame.z,Zx,Zy,locRC,directionIndex,dirsVec);
    end
        
    validEdgePixels = zGradInDirection > params.gradZTh & isSupressed;
    
    zGradInDirection = zGradInDirection(validEdgePixels);
    edgeSubPixel = edgeSubPixel(validEdgePixels,:);
    zValuesForSubEdges = zValuesForSubEdges(validEdgePixels);
    dirPerPixel = dirPerPixel(validEdgePixels);
    sectionMapDepth = sectionMapValid(validEdgePixels);
    directionIndex = directionIndex(validEdgePixels);
    directionIndex(directionIndex>4) = directionIndex(directionIndex>4)-4;% Like taking abosoulte value on the direction
    
    weights = min(max(zGradInDirection - params.gradZTh,0),params.gradZMax - params.gradZTh);
    if params.constantWeights
        weights(:) = params.constantWeightsValue;
    end
    
    
    xim = edgeSubPixel(:,1)-1;
    yim = edgeSubPixel(:,2)-1;
    
    subPoints = [xim,yim,ones(size(yim))];
    vertices = subPoints*(pinv(params.Kdepth)').*zValuesForSubEdges/single(params.zMaxSubMM);
    
        
end
function [locRCsub,zValue,zGradInDirection] = subEdgesByForLoop(iEdge,Zim,Zx,Zy,locRC,directionIndex,dirsVec)

    for i = 1:size(locRC,1)
        % Take the right direction
        currDir = dirsVec(directionIndex(i),:);
        localRegion = locRC(i,:) + vec(-2:1)*currDir;
        localEdges = interp2(iEdge,localRegion(:,2),localRegion(:,1));
        isSupressed(i) = localEdges(3) >= localEdges(2) && localEdges(3) >= localEdges(4);
        
        fraqStep = (-0.5*(localEdges(4)-localEdges(2))./(localEdges(4)+localEdges(2)-2*localEdges(3))); % The step we need to move to reach the subpixel gradient i nthe gradient direction
        fraqStep((localEdges(4)+localEdges(2)-2*localEdges(3))==0) = 0;
        
        locRCsub(i,:) = locRC(i,:) + fraqStep.*currDir;
        
        % Calculate the Z gradient for thresholding
        localZx = interp2(Zx,localRegion(2:3,2),localRegion(2:3,1));
        localZy = interp2(Zy,localRegion(2:3,2),localRegion(2:3,1));
        zGrad = mean([localZy,localZx]);
        zGradInDirection(i) = abs(dot(zGrad,currDir/norm(currDir)));
        % Take the z value of the closest part of the edge
        localZvalues = interp2(Zim,localRegion(:,2),localRegion(:,1));
        zValue(i) = min(localZvalues);
    end
end


function [edgeSupressed,edgeSubPixel,valuesForSubEdges,dirI] = subpixelEdges(I,iEdge,Ix,Iy,validEdgePixels)

    sz = size(I); 
    [gridX,gridY] = meshgrid(1:sz(2),1:sz(1)); % gridX/Y contains the indices of the pixels
    directionInDeg = atan2d(Iy,Ix);% For each pixel, we can calculate the direction of the gradient in degrees
    [~,dirI] = min(abs(directionInDeg - reshape([0,45,90,135,180,225,270,315],1,1,[])),[],3); % Quantize the direction to 4 directions (don't care about the sign)
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
