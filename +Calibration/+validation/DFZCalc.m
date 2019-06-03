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

        px = reshape(dbg.v(:,1),dbg.gridSize);
        py = reshape(dbg.v(:,2),dbg.gridSize);
        pz = reshape(dbg.v(:,3),dbg.gridSize);
        ptx = reshape(dbg.gridPoints(:,1),dbg.gridSize);
        pty = reshape(dbg.gridPoints(:,2),dbg.gridSize);
        distX = sqrt(diff(px,1,2).^2+diff(py,1,2).^2+diff(pz,1,2).^2)/params.target.squareSize-1;
        distY = sqrt(diff(px,1,1).^2+diff(py,1,1).^2+diff(pz,1,1).^2)/params.target.squareSize-1;

        imSize  = fliplr(size(frames(1).i));
        [yg,xg]=ndgrid(0:imSize(2)-1,0:imSize(1)-1);
    
        
        F = scatteredInterpolant(vec(ptx(1:end,1:end-1)),vec(pty(1:end,1:end-1)),vec(distX(1:end,:)), 'natural','none');
        scaleImX = F(xg, yg);
        F = scatteredInterpolant(vec(ptx(1:end-1,1:end)),vec(pty(1:end-1,1:end)),vec(distY(1:end,:)), 'natural','none');
        scaleImY = F(xg, yg);
        
        ff = Calibration.aux.invisibleFigure();
        imagesc(scaleImX);colormap jet;colorbar;
        title(sprintf('Scale Error Image X'));
        Calibration.aux.saveFigureAsImage(ff,runParams,'Validation','ScaleErrorImageX',1);
        
        ff = Calibration.aux.invisibleFigure();
        imagesc(scaleImY);colormap jet;colorbar;
        title(sprintf('Scale Error Image Y'));
        Calibration.aux.saveFigureAsImage(ff,runParams,'Validation','ScaleErrorImageY',1);
        
        

        
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
