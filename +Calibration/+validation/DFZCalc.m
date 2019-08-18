function [dfzRes,allRes,dbg1] = DFZCalc(params,frames,runParams,fprintff)
dfzRes = [];

if params.sampleZFromWhiteCheckers
    params.sampleZFromWhiteCheckers = 0;
    [score1, allRes1,dbg1] = Validation.metrics.gridInterDist(rotFrame180(frames), params);
    params.sampleZFromWhiteCheckers = 1;
    [score2, allRes2,dbg2] = Validation.metrics.gridInterDist(rotFrame180(frames), params);
else
    [score1, allRes1,dbg1] = Validation.metrics.gridInterDist(rotFrame180(frames), params);
end

if exist('runParams','var')
    imSize  = fliplr(size(frames(1).i));
    saveFigs(dbg1,runParams,params,imSize, 'SampleZFromCorners'); 
    if params.sampleZFromWhiteCheckers
        saveFigs(dbg2,runParams,params,imSize,'SampleZFromWhiteCheckers');
    end
end

dfzRes.GeometricErrorReg = score1;

[~, geomRes,dbg] = Validation.metrics.geomUnproject(rotFrame180(frames), params);
dfzRes.reprojRmsPix = geomRes.reprojRmsPix;
dfzRes.reprojZRms = geomRes.reprojZRms;
dfzRes.irDistanceDrift = geomRes.irDistanceDrift;

% Line fit results:
dfzRes.lineFitMeanRmsErrHor3dReg = allRes1.lineFit.lineFitMeanRmsErrorTotalHoriz3D;
dfzRes.lineFitMeanRmsErrVer3dReg = allRes1.lineFit.lineFitMeanRmsErrorTotalVertic3D;
dfzRes.lineFitMaxRmsErrHor3dReg = allRes1.lineFit.lineFitMaxRmsErrorTotalHoriz3D;
dfzRes.lineFitMaxRmsErrVer3dReg = allRes1.lineFit.lineFitMaxRmsErrorTotalVertic3D;
dfzRes.lineFitMaxErrHor3dReg = allRes1.lineFit.lineFitMaxErrorTotalHoriz3D;
dfzRes.lineFitMaxErrVer3dReg = allRes1.lineFit.lineFitMaxErrorTotalVertic3D;
dfzRes.lineFitMeanRmsErrHor2dReg = allRes1.lineFit.lineFitMeanRmsErrorTotalHoriz2D;
dfzRes.lineFitMeanRmsErrVer2dReg = allRes1.lineFit.lineFitMeanRmsErrorTotalVertic2D;
dfzRes.lineFitMaxRmsErrHor2dReg = allRes1.lineFit.lineFitMaxRmsErrorTotalHoriz2D;
dfzRes.lineFitMaxRmsErrVer2dReg = allRes1.lineFit.lineFitMaxRmsErrorTotalVertic2D;
dfzRes.lineFitMaxErrHor2dReg = allRes1.lineFit.lineFitMaxErrorTotalHoriz2D;
dfzRes.lineFitMaxErrVer2dReg = allRes1.lineFit.lineFitMaxErrorTotalVertic2D;
if params.sampleZFromWhiteCheckers
    dfzRes.GeometricErrorWht = score2;
    
    dfzRes.lineFitMeanRmsErrHor3dWht = allRes2.lineFit.lineFitMeanRmsErrorTotalHoriz3D;
    dfzRes.lineFitMeanRmsErrVer3dWht = allRes2.lineFit.lineFitMeanRmsErrorTotalVertic3D;
    dfzRes.lineFitMaxRmsErrHor3dWht = allRes2.lineFit.lineFitMaxRmsErrorTotalHoriz3D;
    dfzRes.lineFitMaxRmsErrVer3dWht = allRes2.lineFit.lineFitMaxRmsErrorTotalVertic3D;
    dfzRes.lineFitMaxErrHor3dWht = allRes2.lineFit.lineFitMaxErrorTotalHoriz3D;
    dfzRes.lineFitMaxErrVer3dWht = allRes2.lineFit.lineFitMaxErrorTotalVertic3D;
    dfzRes.lineFitMeanRmsErrHor2dWht = allRes2.lineFit.lineFitMeanRmsErrorTotalHoriz2D;
    dfzRes.lineFitMeanRmsErrVer2dWht = allRes2.lineFit.lineFitMeanRmsErrorTotalVertic2D;
    dfzRes.lineFitMaxRmsErrHor2dWht = allRes2.lineFit.lineFitMaxRmsErrorTotalHoriz2D;
    dfzRes.lineFitMaxRmsErrVer2dWht = allRes2.lineFit.lineFitMaxRmsErrorTotalVertic2D;
    dfzRes.lineFitMaxErrHor2dWht = allRes2.lineFit.lineFitMaxErrorTotalHoriz2D;
    dfzRes.lineFitMaxErrVer2dWht = allRes2.lineFit.lineFitMaxErrorTotalVertic2D;
end
[allResReg] = addPostfixToStructField(allRes1, 'reg');
[allResWht] = addPostfixToStructField(allRes2, 'Wht');

params.sampleZFromWhiteCheckers = 1;
[~, planeFitResWht,~] = Validation.metrics.planeFitOnCorners(rotFrame180(frames), params);
dfzRes.planeFitMeanRmsErrWht = planeFitResWht.rmsPlaneFitDist;
dfzRes.planeFitMaxErrWht = planeFitResWht.maxPlaneFitDist;

params.sampleZFromWhiteCheckers = 0;
params.sampleZFromBlackCheckers = 1;
[~, planeFitResBlck,~] = Validation.metrics.planeFitOnCorners(rotFrame180(frames), params);
dfzRes.planeFitMeanRmsErrBlck = planeFitResBlck.rmsPlaneFitDist;
dfzRes.planeFitMaxErrBlck = planeFitResBlck.maxPlaneFitDist;


allRes = Validation.aux.mergeResultStruct(allResReg,allResWht);
allRes = Validation.aux.mergeResultStruct(allRes,geomRes);
allRes = Validation.aux.mergeResultStruct(allRes,planeFitResWht);
allRes = Validation.aux.mergeResultStruct(allRes,planeFitResBlck);

fprintff('%s: %2.4g\n','eGeomReg',score1);
end

function rotFrame = rotFrame180(frame)
rotFrame.i = rot90(frame.i,2);
rotFrame.z = rot90(frame.z,2);
%    rotFrame.c = rot90(frame.c,2);
end


function [] = saveFigs(dbg,runParams,params,imSize,prefixStr)
ff = Calibration.aux.invisibleFigure();
imagesc(dbg.ir);
pCirc = Calibration.DFZ.getCBCircPoints(dbg.gridPoints,dbg.gridSize);
hold on;
plot(pCirc(:,1),pCirc(:,2),'r','linewidth',2);
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