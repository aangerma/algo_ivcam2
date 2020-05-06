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
    
    if 1
        
        locRC = [sampleByMask(gridY,validEdgePixelsByIR),sampleByMask(gridX,validEdgePixelsByIR)];
        sectionMapValid = sampleByMask(sectionMapDepth,validEdgePixelsByIR);
        IxValid = sampleByMask(Ix,validEdgePixelsByIR);
        IyValid = sampleByMask(Iy,validEdgePixelsByIR);
    else
        locRC = [gridY(validEdgePixelsByIR),gridX(validEdgePixelsByIR)];
        sectionMapValid = sectionMapDepth(validEdgePixelsByIR);
        IxValid = Ix(validEdgePixelsByIR);
        IyValid = Iy(validEdgePixelsByIR);
    end
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
        
    validEdgePixels = zGradInDirection > params.gradZTh & isSupressed & zValuesForSubEdges > 0;
    
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
    
    [uv,~,~] = OnlineCalibration.aux.projectVToRGB(vertices,params.rgbPmat,params.Krgb,params.rgbDistort);
    isInside = OnlineCalibration.aux.isInsideImage(uv,flip(params.rgbRes));
    
    xim = xim(isInside);
    yim = yim(isInside); 
    zValuesForSubEdges = zValuesForSubEdges(isInside);
    zGradInDirection = zGradInDirection(isInside);
    directionIndex = directionIndex(isInside);
    weights = weights(isInside);
    vertices = vertices(isInside,:);
    sectionMapDepth = sectionMapDepth(isInside);
end

function [values] = sampleByMask(I,binMask)
    % Extract values from image I using the binMask with the order being
    % row and then column
    I = I';
    values = I(binMask');
    
    
end