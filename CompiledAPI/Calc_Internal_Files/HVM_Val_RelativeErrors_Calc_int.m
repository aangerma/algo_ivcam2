function [results,data] = HVM_Val_RelativeErrors_Calc_int(frameBytes, sz, params, runParams,distanceVector)
%HVM_VAL_RELATIVEERRORS_CALC_INT 
% Recieves captures of N CB scenes. Calculates the horizontal angle and
% vertical angle of each 

% For each frame - get 560x3 vertices

% For each of the vertices - calculate plane angle (on common corners / on
% all by flag)

% Calculate the best movement vector that explains the robot movement
% between frames

% Sample the range to the points crosing the movment vector. Do it by
% interpolation.

% The results should output - 
% 1. Max-Min tilt angle X and Y in degrees
% 2. Mean tilt angle
% 3. R values along the trajectory of the movement
% 4. R acc values - (1-deltaR)/Given distances
% 5. mean plane fit errors from white or black corners
% 6. dbg - Plane fit errors on the images: White corners, Black corners

% I and Z frames
frames = Calibration.aux.convertBytesToFrames(frameBytes, sz, [], true);  

zMaxSubMM = single(params.camera.zMaxSubMM);
matK = params.camera.K;
matKi = double(matK)^-1;
% Get corners vertices and plane fit data for black and white
for i = 1:numel(frames)
    
    try
        CB = CBTools.Checkerboard (frames(i).i,'targetType', 'checkerboard_Iv2A1','imageRotatedBy180Flag',true, 'cornersDetectionThreshold', 0.2,'nonRectangleFlag',true);  
        pts = CB.getGridPointsMat;
        colors = CB.getColorMap;
    catch
        CB = CBTools.Checkerboard (frames(i).i,'targetType', 'checkerboard_Iv2A1','imageRotatedBy180Flag',true);  
        pts = CB.getGridPointsMat;
        colors = CB.getColorMap;
    end
    for c = 0:1
    % Sample the Z from white and from black to simulate 2 different
    % reflectivities
        if c
            colorsc = colors;
            fname = 'white';
        else
            colorsc = 1-colors;
            fname = 'black';
        end
        [zSampled,~,~,data.(fname).frameData(i).pts,~] = CBTools.valuesFromWhitesNonSq(frames(i).z,pts,colorsc,1/8);
        data.(fname).frameData(i).pts = reshape(data.(fname).frameData(i).pts,[],2);
        data.(fname).frameData(i).zSampled = zSampled;
        % Generate vertices for black and white
        v = [data.(fname).frameData(i).pts,ones(size(data.(fname).frameData(i).pts,1),1)]';
        data.(fname).frameData(i).V = (matKi*v)'.*zSampled/zMaxSubMM;
        data.(fname).frameData(i).medianZ = nanmedian(data.(fname).frameData(i).V(:,3));
        % For vW and vB: perform plane fit and get the hoizontal and vertical
        % angles
        data.(fname).frameData(i).pf = planeFitData(data.(fname).frameData(i).V);
        [res,~] = findGridError(data.(fname).frameData(i).V,CB.gridSize);
        data.(fname).frameData(i).gid = res.errorMean;
    end
    
end


%% Find the vector that best explains the movement of the camera between frames
% Look for a vector v0, which best describes the movement. 
% Calculate the differences between every two captures, perform PCA on the
% differences and get the largest eigen vector


% %%%%%%%%%%%%%%
% for i = 1:numel(data.black)
%     data.black(i).V = data.black(i).V + (i-1)*[0,0,20];
%     data.white(i).V = data.white(i).V + (i-1)*[0,0,20];
% end
% %%%%%%%%%%
fnames = {'white';'black'};
for c = 1:numel(fnames)
    allVerts = reshape([data.(fnames{c}).frameData.V],560,3,[]);
    validCB = all(~isnan(allVerts(:,1,:)),3);
    combs = nchoosek(1:numel(data.(fnames{c}).frameData),2);
    dV = [];
    for i = 1:size(combs,1)
        dV = [dV;data.(fnames{c}).frameData(combs(i,1)).V(validCB,:) - data.(fnames{c}).frameData(combs(i,2)).V(validCB,:)];
    end
    dV = [dV;-dV];
    [~,~,eigenVectors] = svd(dV'*dV);

    movmentVector = eigenVectors(:,1);
    combs = nchoosek(1:numel(data.(fnames{c}).frameData),2);
    distMat = zeros(numel(data.(fnames{c}).frameData));
    for i = 1:size(combs,1)
        distMat(combs(i,1),combs(i,2)) = mean((data.(fnames{c}).frameData(combs(i,1)).V(validCB,:) - data.(fnames{c}).frameData(combs(i,2)).V(validCB,:)))*movmentVector;
    end
    distMat = distMat - distMat';
    movementAxisPixel = matK*movmentVector;
    movementAxisPixel = [movementAxisPixel(1)/movementAxisPixel(3),movementAxisPixel(2)/movementAxisPixel(3)]+1;
    
    data.(fnames{c}).distMat = distMat;
    data.(fnames{c}).movmentVector = movmentVector;
    data.(fnames{c}).movmentVectorAngX = atand(movmentVector(1)/movmentVector(3));
    data.(fnames{c}).movmentVectorAngY = atand(movmentVector(2)/movmentVector(3));
    data.(fnames{c}).movementAxisPixel = movementAxisPixel;
    
    
    
    % Measure the distance of the cb at the axis of the movement
    for i = 1:numel(data.(fnames{c}).frameData)
        F = scatteredInterpolant(data.(fnames{c}).frameData(i).pts(validCB,1),data.(fnames{c}).frameData(i).pts(validCB,2),double(data.(fnames{c}).frameData(i).zSampled(validCB)/zMaxSubMM));
        data.(fnames{c}).frameData(i).distanceAtMovementPixel = F(double(movementAxisPixel(1)),double(movementAxisPixel(2)));
    end
    
end




% figure;
% for i = 1:numel(frames)
%    tabplot(i);
%    imagesc(frames(i).i);
%    hold on
%    plot(movementAxisPixel(1),movementAxisPixel(1),'ro')
% end

for c = 1:2
    % relative tilt
    pf = [data.(fnames{c}).frameData.pf];
    hAngles = [pf.horizAngle];
    vAngles = [pf.verticalAngle];
    results.(fnames{c}).horizAngleMean = mean(hAngles);
    results.(fnames{c}).horizAngleMaxDiff = max(hAngles)-min(hAngles);
    results.(fnames{c}).verticalAngleMean = mean(vAngles);
    results.(fnames{c}).verticalAngleMaxDiff = max(vAngles)-min(vAngles);
    results.(fnames{c}).planeFitRms = mean([pf.planeFitErrorRms]);
    results.(fnames{c}).planeFitMax = max([pf.planeFitErrorRms]);
    results.(fnames{c}).planeFitMin = min([pf.planeFitErrorRms]);
    
    % relative z accuracy
    if numel(diff(distanceVector(:)))== numel(diff(data.(fnames{c}).distMat(:,1)))
        results.(fnames{c}).zDiffMeanError = mean(abs(diff(data.(fnames{c}).distMat(:,1)))-abs(diff(distanceVector(:))));

        
        results.(fnames{c}).zMovement = data.(fnames{c}).movmentVector(3)*data.white.distMat(2,1);
        results.(fnames{c}).zFromCBFirstFrame = data.(fnames{c}).frameData(1).distanceAtMovementPixel;
        results.(fnames{c}).zFromCBLastFrame = data.(fnames{c}).frameData(2).distanceAtMovementPixel;
        
        results.(fnames{c}).medianZFirstFrame = data.(fnames{c}).frameData(1).medianZ;
        results.(fnames{c}).medianZLastFrame = data.(fnames{c}).frameData(2).medianZ;
    end
    
    measDistances = [data.(fnames{c}).frameData.distanceAtMovementPixel];
    distDiff = measDistances(:)-distanceVector(:);
    results.(fnames{c}).zAccMMMeanError = mean(distDiff);
    results.(fnames{c}).zAccPrcntMeanError = mean(abs(distDiff./distanceVector(:))*100);
    results.(fnames{c}).zAccPrcntMaxError = max(abs(distDiff./distanceVector(:))*100);
    results.(fnames{c}).zAccPrcntMinError = min(abs(distDiff./distanceVector(:))*100);
    
    results.(fnames{c}).planeFitFirstImg = pf(1).planeFitErrorRms;
    results.(fnames{c}).gidFirstImg = data.(fnames{c}).frameData(1).gid;
    
end




if ~isempty(runParams)
    legends = fnames;
    ff = Calibration.aux.invisibleFigure;
    
    subplot(3,2,1);
    plot(distanceVector,[data.(fnames{1}).frameData.distanceAtMovementPixel]);
    hold on
    plot(distanceVector,[data.(fnames{2}).frameData.distanceAtMovementPixel]);
    plot(distanceVector,distanceVector,'go')
    title('MeasuredDistance Vs Given Distance');
    xlabel('Target Distance GT (mm)');
    ylabel('Target Distance Measured (mm)');
    legend(legends,'Location','northwest');
    grid minor;

    subplot(3,2,2);
    plot(diff(distanceVector));
    hold on
    plot(diff(data.(fnames{1}).distMat(:,1))  );
    plot(diff(data.(fnames{2}).distMat(:,1))  );
    title('Differences Between Sequential Frames');
    xlabel('dFrame');
    ylabel('mm');
    legend(['Expected';legends],'Location','northwest');
    grid minor;

    subplot(3,2,3);
    hold on
    plot(distanceVector, [data.(fnames{1}).frameData.gid] );
    plot(distanceVector, [data.(fnames{2}).frameData.gid] );
    title('GID Over Frames');
    xlabel('Distance (mm)');
    ylabel('mm');
    legend(legends,'Location','northwest');
    grid minor;
    
    
    plf(1,:) = [data.(fnames{1}).frameData.pf];
    plf(2,:) = [data.(fnames{2}).frameData.pf];

    
    subplot(3,2,4);
    hold on
    plot(distanceVector, [plf(1,:).planeFitErrorRms]   );
    plot(distanceVector, [plf(2,:).planeFitErrorRms]   );
    title('Plane Fit RMS Over Frames');
    xlabel('Distance (mm)');
    ylabel('mm');
    legend(legends,'Location','northwest');
    grid minor;

    subplot(3,2,5);
    hold on
    plot(distanceVector, [plf(1,:).horizAngle]   );
    plot(distanceVector, [plf(2,:).horizAngle]   );
    title('Plane Fit Horiz Angle Over Frames');
    xlabel('Distance (mm)');
    ylabel('mm');
    legend(legends,'Location','northwest');
    grid minor;

    subplot(3,2,6);
    hold on
    plot(distanceVector, [plf(1,:).verticalAngle]   );
    plot(distanceVector, [plf(2,:).verticalAngle]   );
    title('Plane Fit Vertical Angle Over Frames');
    xlabel('Distance (mm)');
    ylabel('mm');
    legend(legends,'Location','northwest');
    grid minor;

    

    
    
    Calibration.aux.saveFigureAsImage(ff,runParams,'RelativeErrors','Acc_GID_PlaneFit',1,0,0);
    Calibration.aux.saveFigureAsImage(ff,runParams,'RelativeErrors','Acc_GID_PlaneFit',1,1,1);
end


end

function s = planeFitData(vertices)
    [distError, p, ~] = Validation.aux.planeFitInternal(vertices(~isnan(vertices(:,1)),:));
    s.planeFitErrorRms = rms(distError);
    s.horizAngle = (90-atan2d(p(3),p(1)));
    s.verticalAngle = (90-atan2d(p(3),p(2)));
end
function[Result,dbg] = findGridError(gridVertices,gridSize)
% if isstruct(frame)
%     vararg ={'targetType', params.target.target, 'params_camera',params.camera,'nonRectangleFlag',params.nonRectangleFlag,'cornersReferenceDepth',params.cornersReferenceDepth,'slimNansflag',true};
%     CB = CBTools.Checkerboard (frame,vararg{:});
%     gridVertices = CB.getGridVerticesList;
%     gridSize = CB.gridSize;
% else
%     CB = [];
%     gridVertices = frame;
%     gridSize = params.gridSize;
% end
params.target.squareSize = 30;
n = size(gridVertices, 1);
[sy, sx] = ndgrid((1:gridSize(1))*params.target.squareSize, (1:gridSize(2))*params.target.squareSize);% ideal corner grid
[iy, ix] = ndgrid(1:n, 1:n);
X = ix(:);
Y = iy(:);
% gridVertices should be the matrix %
dbg.dv = sqrt((gridVertices(X,1)-gridVertices(Y,1)).^2 + (gridVertices(X,2)-gridVertices(Y,2)).^2 + (gridVertices(X,3)-gridVertices(Y,3)).^2);% Distance from each corner vertices  to the other
dbg.ds = sqrt((sx(X)-sx(Y)).^2 + (sy(X)-sy(Y)).^2);% Distance from each ideal corner to the other
dbg.scaleErrors = dbg.dv-dbg.ds; % differance between detected vertices distance to the ideal 
Result.errorMean = nanmean(abs(dbg.scaleErrors)); 
Result.errorRms = sqrt(nanmean((dbg.scaleErrors).^2)); 
Result.scaleError = nanmean((dbg.scaleErrors)./dbg.ds);
end