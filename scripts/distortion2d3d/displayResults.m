runNum = 4;
units = {'F9240031'; 'F9240032'; 'F9240073';'F9240021'};
load(['X:\Data\distortion\3Images\run' num2str(runNum) '\workspaceVars.mat']);
figure;
for k = 1:length(allVerticesToday)
    tabplot;
   
    v4 = allVerticesToday{1,k};
    scatter3(v4(:,1),v4(:,2),v4(:,3),'rx');
    [rows,cols,vNoNanCropped] = getVerticesWithoutNans(allVerticesCropped{1,k},checkerSize);
     % Adjust the checker points to match the vertices points in the cropped area
    vCheckerCropped = reshape(d(k).pts3d,checkerSize(1),checkerSize(2),checkerSize(3));
    vCheckerCropped = vCheckerCropped(rows,cols,:);
    vCheckerCropped = reshape(vCheckerCropped,[],3);
    % Calculate rotation and shift of rigid fit for cropped points
    [~,~,rotmat,shiftVec, meanVal] = Calibration.aux.rigidFit(vNoNanCropped,vCheckerCropped);
    [rows,cols,vResult] = getVerticesWithoutNans(v4,checkerSize);
    % Perform rotation and scale to the 3D points to get the fitted vertices and normalize to a unit vector
    vChecker = reshape(d(k).pts3d,checkerSize(1),checkerSize(2),checkerSize(3));
    vChecker = vChecker(rows,cols,:);
    vChecker = reshape(vChecker,[],3);
    vFit = (vChecker-meanVal)*rotmat'+shiftVec;
    hold on; scatter3(vFit(:,1),vFit(:,2),vFit(:,3),'g');
    v7 = allVerticesDFZcroppedDfzFullTpsDfz{1,k};
    hold on; scatter3(v7(:,1),v7(:,2),v7(:,3),'bx');
    v3 = allVerticesDFZcroppedTpsNdfzFull{1,k};
    hold on; scatter3(v3(:,1),v3(:,2),v3(:,3),'kx');
    legend('Today','Rigit fit model from cropped, on today', 'Option 3', 'Option 7');
    xlabel('x axis [mm]');ylabel('y axis [mm]');zlabel('z axis [mm]');
    title(['Run #' num2str(runNum) ', Unit #' units{runNum,1}]);
    hold off;
end