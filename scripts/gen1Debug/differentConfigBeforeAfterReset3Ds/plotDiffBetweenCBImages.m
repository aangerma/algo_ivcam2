function [ fdata ] = plotDiffBetweenCBImages( frames,K,z2mm ,runParams)
for i = 1:numel(frames)
    frames(i) = rotFrame180(frames(i));
end

params.camera.zMaxSubMM = z2mm;
params.camera.K = K;
params.target.squareSize = 30;
params.expectedGridSize = [];


for i = 1:numel(frames)
    pts = CBTools.findCheckerboardFullMatrix(frames(i).i, 0);
    data.ptsFull = pts;
    data.pts = reshape(pts,[],2);
    data.v = Validation.aux.pointsToVertices(reshape(pts,[],2), frames(i).z, params.camera);
    data.vFull = reshape(data.v,[size(pts,1),size(pts,2),3]);
    data.r = sqrt(sum(data.v.^2,2));
    [data.score,~,~] = Validation.metrics.gridInterDist(frames(i), params);
    fdata(i) = data;
    
    
end





ff = Calibration.aux.invisibleFigure;
axis([0,640,0,360])
for i = 1:numel(frames)
    hold on
    plot(fdata(i).pts(:,1),fdata(i).pts(:,2),'*');
end
title('CB corners in image plane')
Calibration.aux.saveFigureAsImage(ff,runParams,'CompareCalVal','CB_locations');


ff = Calibration.aux.invisibleFigure;
diff = sqrt(sum((fdata(1).ptsFull - fdata(2).ptsFull).^2,3));
imagesc(diff);
colorbar;
title('Total Pixel Movement');
Calibration.aux.saveFigureAsImage(ff,runParams,'CompareCalVal','XY_Pixel_Diff');


ff = Calibration.aux.invisibleFigure;
diff = fdata(1).ptsFull(:,:,1) - fdata(2).ptsFull(:,:,1);
imagesc(diff);
colorbar;
title('X Pixel Movement');
Calibration.aux.saveFigureAsImage(ff,runParams,'CompareCalVal','X_Pixel_Diff');

ff = Calibration.aux.invisibleFigure;
diff = fdata(1).ptsFull(:,:,2) - fdata(2).ptsFull(:,:,2);
imagesc(diff);
colorbar;
title('Y Pixel Movement');
Calibration.aux.saveFigureAsImage(ff,runParams,'CompareCalVal','Y_Pixel_Diff');


ff = Calibration.aux.invisibleFigure;
quiver(fdata(1).pts(:,1),fdata(1).pts(:,2),fdata(1).pts(:,1)-fdata(2).pts(:,1),fdata(1).pts(:,2)-fdata(2).pts(:,2));
axis([0,640,0,360]);
title('Pixel Movement Quiver'); 
Calibration.aux.saveFigureAsImage(ff,runParams,'CompareCalVal','XY_Pixel_Quiver');


ff = Calibration.aux.invisibleFigure;
diff = fdata(1).vFull(:,:,1) - fdata(2).vFull(:,:,1);
imagesc(diff);
colorbar;
title('X mm Movement');
Calibration.aux.saveFigureAsImage(ff,runParams,'CompareCalVal','X_Diff_mm');


ff = Calibration.aux.invisibleFigure;
diff = fdata(1).vFull(:,:,2) - fdata(2).vFull(:,:,2);
imagesc(diff);
colorbar;
title('Y mm Movement');
Calibration.aux.saveFigureAsImage(ff,runParams,'CompareCalVal','Y_Diff_mm');


ff = Calibration.aux.invisibleFigure;
diff = fdata(1).vFull(:,:,3) - fdata(2).vFull(:,:,3);
imagesc(diff);
colorbar;
title('Z mm Movement');
Calibration.aux.saveFigureAsImage(ff,runParams,'CompareCalVal','Z_Diff_mm');


ff = Calibration.aux.invisibleFigure;
diff = sqrt(sum(fdata(1).vFull.^2,3)) - sqrt(sum(fdata(2).vFull.^2,3));
imagesc(diff);
colorbar;
title('R mm Movement');
Calibration.aux.saveFigureAsImage(ff,runParams,'CompareCalVal','R_Diff');


ff = Calibration.aux.invisibleFigure;
histogram(diff,-10:0.25:10);
title('Cal-Val R Diff Histogram');
xlabel('R Cal-Val');
Calibration.aux.saveFigureAsImage(ff,runParams,'CompareCalVal','R_Diff_Hist');

end

function rotFrame = rotFrame180(frame)
    rotFrame.i = rot90(frame.i,2);
    rotFrame.z = rot90(frame.z,2);
    rotFrame.c = rot90(frame.c,2);
end

