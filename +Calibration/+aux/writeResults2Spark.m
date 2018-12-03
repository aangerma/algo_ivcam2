function writeResults2Spark(results,s,errRange,write2spark)
    if write2spark
        f = fieldnames(results);
        for i = 1:length(f)
            s.AddMetrics(f{i}, results.(f{i}),errRange.(f{i})(1),errRange.(f{i})(2),true);
        end
    end
    
end