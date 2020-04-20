function metrics = GetGeomMetricsResults(vertices, params)
    
    allRes = struct;
    [~, results, ~] = Validation.metrics.gridInterDistance(vertices, params);
    allRes = mergestruct(allRes, results);
    [~, results, ~] = Validation.metrics.gridDistortion(vertices, params);
    allRes = mergestruct(allRes, results);
    [~, results, ~] = Validation.metrics.gridLineFit(vertices, params);
    allRes = mergestruct(allRes, results);
    [~, results, ~] = Validation.metrics.planeFit(vertices, params);
    allRes = mergestruct(allRes, results);
    
    metrics.gid = allRes.errorMeanAF;
    metrics.planeFitRms = allRes.planeFitErrorRmsAF;
    metrics.planeFitmax = allRes.planeFitErrorMaxAF;
    metrics.lineFit2DHorzRms = allRes.lineFit2DRmsErrorTotal_hAF;
    metrics.lineFit2DHorzMax = allRes.lineFit2DMaxErrorTotal_hAF;
    metrics.lineFit2DVertRms = allRes.lineFit2DRmsErrorTotal_vAF;
    metrics.lineFit2DVertMax = allRes.lineFit2DMaxErrorTotal_vAF;
    metrics.lineFit3DHorzRms = allRes.lineFit3DRmsErrorTotal_hAF;
    metrics.lineFit3DHorzMax = allRes.lineFit3DMaxErrorTotal_hAF;
    metrics.lineFit3DVertRms = allRes.lineFit3DRmsErrorTotal_vAF;
    metrics.lineFit3DVertMax = allRes.lineFit3DMaxErrorTotal_vAF;
    
end