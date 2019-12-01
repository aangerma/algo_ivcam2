function [dfzRes,allRes,dbg1] = DFZCalc(params,frames,runParams,fprintff)
dfzRes = [];
params.isRoiRect = params.gidMaskIsRoiRect;
params.target.target = 'checkerboard_Iv2A1'; 
params.cornersReferenceDepth = 'corners';
allRes1 = [];
dbg1 = [];
[~, results,dbg] = Validation.metrics.gridInterDistance(rotFrame180(frames), params);
allRes1 = mergestruct(allRes1,results);
dbg1 = mergestruct(dbg1,dbg);
[~, results,dbg] = Validation.metrics.gridDistortion;
allRes1 = mergestruct(allRes1,results);
dbg1 = mergestruct(dbg1,dbg);
[~, results,dbg] = Validation.metrics.gridLineFit;
allRes1 = mergestruct(allRes1,results);
dbg1 = mergestruct(dbg1,dbg);
if params.sampleZFromWhiteCheckers
    params.cornersReferenceDepth = 'white'; 
    allRes2 = [];
    dbg2 = [];
    [~, results,dbg] = Validation.metrics.gridInterDistance(rotFrame180(frames), params);
    allRes2 = mergestruct(allRes2,results);
    dbg2 = mergestruct(dbg2,dbg);
    [~, results,dbg] = Validation.metrics.gridDistortion;
    allRes2 = mergestruct(allRes2,results);
    dbg2 = mergestruct(dbg2,dbg);
    [~, results,dbg] = Validation.metrics.gridLineFit;
    allRes2 = mergestruct(allRes2,results);
    dbg2 = mergestruct(dbg2,dbg);
end


if exist('runParams','var')
    imSize  = fliplr(size(frames(1).i));
    saveFigs(dbg1,runParams,params,imSize, 'SampleZFromCorners'); 
    if params.sampleZFromWhiteCheckers
        saveFigs(dbg2,runParams,params,imSize,'SampleZFromWhiteCheckers');
    end
end

[~, results,~] = Validation.metrics.geomReprojectError(rotFrame180(frames), params);
fnames = fieldnames(results);
for i=1:length(fnames)
    allRes.([fnames{i}]) = results.(fnames{i});
end

fnames = fieldnames(allRes1);
for i=1:length(fnames)
    allRes.([fnames{i},'Reg']) = allRes1.(fnames{i});
end
if params.sampleZFromWhiteCheckers
    for i=1:length(fnames)
        allRes.([fnames{i},'Wht']) = allRes1.(fnames{i});
    end
end

[allResReg] = addPostfixToStructField(allRes1, 'reg');
[allResWht] = addPostfixToStructField(allRes2, 'Wht');

params.CB = true;
params.cornersReferenceDepth = 'white';
params.target.target = 'checkerboard_Iv2A1'; 
params.isRoiRect = params.plainFitMaskIsRoiRect;
[~, results,~] = Validation.metrics.planeFit(rotFrame180(frames), params);
fnames = fieldnames(results);
for i=1:length(fnames)
    allRes.([fnames{i},'Wht']) = results.(fnames{i});
end

params.CB = true;
params.cornersReferenceDepth = 'black';
params.target.target = 'checkerboard_Iv2A1'; 
[~, results,~] = Validation.metrics.planeFit(rotFrame180(frames), params);
fnames = fieldnames(results);
for i=1:length(fnames)
    allRes.([fnames{i},'Blck ']) = results.(fnames{i});
end

% fprintff('%s: %2.4g\n','eGeomReg',score1);
end

function rotFrame = rotFrame180(frame)
rotFrame.i = rot90(frame.i,2);
rotFrame.z = rot90(frame.z,2);
%    rotFrame.c = rot90(frame.c,2);
end


function [] = saveFigs(dbg,runParams,params,imSize,prefixStr)
ff = Calibration.aux.invisibleFigure();
imagesc(dbg.ir);
% pCirc = Calibration.DFZ.getCBCircPoints(dbg.gridPoints,dbg.gridSize);
hold on;
% plot(pCirc(:,1),pCirc(:,2),'r','linewidth',2);
hold off
title(sprintf('Validation interDist image: Grid=[%d,%d] %s',dbg.gridSize(1),dbg.gridSize(2),prefixStr));
Calibration.aux.saveFigureAsImage(ff,runParams,'Validation',['GridInterdistImage' prefixStr],1);

ff = Calibration.aux.invisibleFigure();
plot(dbg.r,'*');
title(['r for cb points ' prefixStr]);
Calibration.aux.saveFigureAsImage(ff,runParams,'Validation',['R for CB points' prefixStr],1);

px = reshape(dbg.v(:,1),dbg.gridSize);
py = reshape(dbg.v(:,2),dbg.gridSize);
pz = reshape(dbg.v(:,3),dbg.gridSize);
ptx = reshape(dbg.gridPoints(:,1),dbg.gridSize);
pty = reshape(dbg.gridPoints(:,2),dbg.gridSize);
distX = sqrt(diff(px,1,2).^2+diff(py,1,2).^2+diff(pz,1,2).^2)/params.target.squareSize-1;
distY = sqrt(diff(px,1,1).^2+diff(py,1,1).^2+diff(pz,1,1).^2)/params.target.squareSize-1;

[yg,xg]=ndgrid(0:imSize(2)-1,0:imSize(1)-1);


F = scatteredInterpolant(vec(ptx(1:end,1:end-1)),vec(pty(1:end,1:end-1)),vec(distX(1:end,:)), 'natural','none');
scaleImX = F(xg, yg);
F = scatteredInterpolant(vec(ptx(1:end-1,1:end)),vec(pty(1:end-1,1:end)),vec(distY(1:end,:)), 'natural','none');
scaleImY = F(xg, yg);

ff = Calibration.aux.invisibleFigure();
imagesc(scaleImX);colormap jet;colorbar;
title(sprintf('Scale Error Image X %s', prefixStr));
Calibration.aux.saveFigureAsImage(ff,runParams,'Validation',['ScaleErrorImageX' prefixStr],1);

ff = Calibration.aux.invisibleFigure();
imagesc(scaleImY);colormap jet;colorbar;
title(sprintf('Scale Error Image Y %s',prefixStr));
Calibration.aux.saveFigureAsImage(ff,runParams,'Validation',['ScaleErrorImageY' prefixStr],1);
end

function [structOut] = addPostfixToStructField(structIn, postfix)
fields = fieldnames(structIn);
structVals = struct2cell(structIn);
for k = 1:length(fields)
    structOut.([fields{k,1} postfix]) = structVals{k,1};
end

end