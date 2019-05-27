function [dfzRes,allRes,dbg] = DFZCalc(params,frames,runParams,fprintff)
    dfzRes = [];
    [score, allRes,dbg] = Validation.metrics.gridInterDist(rotFrame180(frames), params);
    
    if exist('runParams','var')
        ff = Calibration.aux.invisibleFigure();
        imagesc(dbg.ir); 
        pCirc = Calibration.DFZ.getCBCircPoints(dbg.gridPoints,dbg.gridSize);
        hold on;
        plot(pCirc(:,1),pCirc(:,2),'r','linewidth',2);
        hold off
        title(sprintf('Validation interDist image: Grid=[%d,%d]',dbg.gridSize(1),dbg.gridSize(2)));
        Calibration.aux.saveFigureAsImage(ff,runParams,'Validation','GridInterdistImage',1);

        ff = Calibration.aux.invisibleFigure();
        plot(dbg.r,'*'); 
        title('r for cb points');
        Calibration.aux.saveFigureAsImage(ff,runParams,'Validation','R for CB points',1);
    end
    
    dfzRes.GeometricError = score;
    [~, geomRes,dbg] = Validation.metrics.geomUnproject(rotFrame180(frames), params);
    dfzRes.reprojRmsPix = geomRes.reprojRmsPix;
    dfzRes.reprojZRms = geomRes.reprojZRms;
    dfzRes.irDistanceDrift = geomRes.irDistanceDrift;
    allRes = Validation.aux.mergeResultStruct(allRes,geomRes);
    fprintff('%s: %2.4g\n','eGeom',score);
end

function rotFrame = rotFrame180(frame)
    rotFrame.i = rot90(frame.i,2);
    rotFrame.z = rot90(frame.z,2);
%    rotFrame.c = rot90(frame.c,2);
end
