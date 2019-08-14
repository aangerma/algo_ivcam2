function [results] = calcLineDistortion(allVertices,Kfor2dError,gridSize)
n = length(allVertices);
lineFitMaxErrorTotal_h3D = NaN(n,1);
lineFitRmsErrorTotal_h3D = NaN(n,1);
lineFitMaxErrorTotal_v3D = NaN(n,1);
lineFitRmsErrorTotal_v3D = NaN(n,1);

lineFitMaxErrorTotal_h2D = NaN(n,1);
lineFitRmsErrorTotal_h2D = NaN(n,1);
lineFitMaxErrorTotal_v2D = NaN(n,1);
lineFitRmsErrorTotal_v2D = NaN(n,1);

if ~exist('gridSize','var') || isempty(gridSize)
    gridSize = [20,28];
end
for k = 1:n
    v = allVertices{1,k};
    v2d = reshape(v,gridSize(1),gridSize(2),3);
    cols = any(~isnan(v2d(:,:,1)),1);
    rows = any(~isnan(v2d(:,:,1)),2);
    v2d = v2d(rows,cols,:);
    
    px = v2d(:,:,1);
    py = v2d(:,:,2);
    pz = v2d(:,:,3);
    pts = cat(3,px,py,pz);
    
    [lineFitResults3D] = Validation.metrics.get3DlineFitErrors(pts);
    lineFitMaxErrorTotal_h3D(k) = lineFitResults3D.lineFitMaxErrorTotal_h;
    lineFitRmsErrorTotal_h3D(k) = lineFitResults3D.lineFitRmsErrorTotal_h;
    lineFitMaxErrorTotal_v3D(k) = lineFitResults3D.lineFitMaxErrorTotal_v;
    lineFitRmsErrorTotal_v3D(k) = lineFitResults3D.lineFitRmsErrorTotal_v;
    
    pixs = Kfor2dError*reshape(pts,[],3)';
    pix_x = pixs(1,:)./pixs(3,:);
    pix_y = pixs(2,:)./pixs(3,:);
    pts = cat(3,reshape(pix_x,size(px)),reshape(pix_y,size(py)),zeros(size(px)));
    
    [lineFitResults2D] = Validation.metrics.get3DlineFitErrors(pts);
    lineFitMaxErrorTotal_h2D(k) = lineFitResults2D.lineFitMaxErrorTotal_h;
    lineFitRmsErrorTotal_h2D(k) = lineFitResults2D.lineFitRmsErrorTotal_h;
    lineFitMaxErrorTotal_v2D(k) = lineFitResults2D.lineFitMaxErrorTotal_v;
    lineFitRmsErrorTotal_v2D(k) = lineFitResults2D.lineFitRmsErrorTotal_v;
end
results.lineFitMeanRmsErrorTotalHoriz3D = nanmean(lineFitRmsErrorTotal_h3D);
results.lineFitMeanRmsErrorTotalVertic3D = nanmean(lineFitRmsErrorTotal_v3D);
results.lineFitMaxRmsErrorTotalHoriz3D = nanmax(lineFitRmsErrorTotal_h3D);
results.lineFitMaxRmsErrorTotalVertic3D = nanmax(lineFitRmsErrorTotal_v3D);
results.lineFitMaxErrorTotalHoriz3D = nanmax(lineFitMaxErrorTotal_h3D);
results.lineFitMaxErrorTotalVertic3D = nanmax(lineFitMaxErrorTotal_v3D);

results.lineFitMeanRmsErrorTotalHoriz2D = nanmean(lineFitRmsErrorTotal_h2D);
results.lineFitMeanRmsErrorTotalVertic2D = nanmean(lineFitRmsErrorTotal_v2D);
results.lineFitMaxRmsErrorTotalHoriz2D = nanmax(lineFitRmsErrorTotal_h2D);
results.lineFitMaxRmsErrorTotalVertic2D = nanmax(lineFitRmsErrorTotal_v2D);
results.lineFitMaxErrorTotalHoriz2D = nanmax(lineFitMaxErrorTotal_h2D);
results.lineFitMaxErrorTotalVertic2D = nanmax(lineFitMaxErrorTotal_v2D);
end