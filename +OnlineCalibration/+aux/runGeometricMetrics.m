function [metrics,dbg] = runGeometricMetrics(frame,params)

par.target.target = params.targetType;
par.camera.zK = params.Kdepth;
par.camera.zMaxSubMM = params.zMaxSubMM;
par.target.squareSize = 30;
[metrics,dbg] = runMetrics(frame,par);

end


function [metrics,dbg] = runMetrics(frame,par)
    [metrics.gid,~,dbg] = Validation.metrics.gridInterDistance(frame, par);
    [~,resultsLF] = Validation.metrics.gridLineFit(frame, par);
    metrics.lineFitRms3D_H = resultsLF.lineFitRmsErrorTotal_hAF;
    metrics.lineFitRms3D_V = resultsLF.lineFitRmsErrorTotal_vAF;
    metrics.lineFitMax3D_H = resultsLF.lineFitMaxErrorTotal_hAF;
    metrics.lineFitMax3D_V = resultsLF.lineFitMaxErrorTotal_vAF;
    metrics.lineFitRms2D_H = resultsLF.lineFit2DRmsErrorTotal_hAF;
    metrics.lineFitRms2D_V = resultsLF.lineFit2DRmsErrorTotal_vAF;
    metrics.lineFitMax2D_H = resultsLF.lineFit2DMaxErrorTotal_hAF;
    metrics.lineFitMax2D_V = resultsLF.lineFit2DMaxErrorTotal_vAF;
    [~,resultsDist] = Validation.metrics.gridDistortion(frame, par);
    metrics.lineFitRms3D_H = resultsDist.horzErrorMeanAF;
    metrics.lineFitRms3D_V = resultsDist.vertErrorMeanAF;
    
    
end

