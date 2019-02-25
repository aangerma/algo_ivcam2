function writeResults2Spark(results,s,errRange,write2spark,prefix)
    if write2spark
        errRangeFields = fieldnames(errRange);
        f = fieldnames(results);
        for i = 1:length(f)
            currMetricName = Calibration.aux.findCurrectErrorPattern(errRangeFields,f{i});
            s.AddMetrics([prefix,'_',f{i}], results.(f{i}),errRange.(currMetricName)(1),errRange.(currMetricName)(2),true);
        end
    end
    
end