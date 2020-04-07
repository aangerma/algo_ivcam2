function metrics = GetGeomMetricsResults(vertices, params)
    
    allRes = struct;
    [~, results, ~] = Validation.metrics.gridInterDistance(vertices, params);
    allRes = mergestruct(allRes, results);
    [~, results, ~] = Validation.metrics.gridDistortion(vertices, params);
    allRes = mergestruct(allRes, results);
    [~, results, ~] = Validation.metrics.gridLineFit(vertices, params);
    allRes = mergestruct(allRes, results);
    results = Validation.aux.calcLineDistortion(vertices, params);
    allRes = mergestruct(allRes, results);
    [~, results, ~] = Validation.metrics.planeFit(vertices, params);
    allRes = mergestruct(allRes, results);
    
    metrics.gid = allRes.errorMeanAF;
    metrics.planeFitRms = allRes.planeFitErrorRmsAF;
    metrics.planeFitmax = allRes.planeFitErrorMaxAF;
    metrics.lineFit2DHorzRms = allRes.lineFitMeanRmsErrorTotalHoriz2D;
    metrics.lineFit2DHorzMax = allRes.lineFitMaxErrorTotalHoriz2D;
    metrics.lineFit2DVertRms = allRes.lineFitMeanRmsErrorTotalVertic2D;
    metrics.lineFit2DVertMax = allRes.lineFitMaxErrorTotalVertic2D;
    metrics.lineFit3DHorzRms = allRes.lineFitRmsErrorTotal_hAF;
    metrics.lineFit3DHorzMax = allRes.lineFitMaxErrorTotal_hAF;
    metrics.lineFit3DVertRms = allRes.lineFitRmsErrorTotal_vAF;
    metrics.lineFit3DVertMax = allRes.lineFitMaxErrorTotal_vAF;
    
end