function  [sparkData, allData] = readHvmSparkMetrics(sparkFile)
    %readHvmSparkMetrics a spark file and extract all the metric
    %information from it
    xmlData = xml2struct_(sparkFile);
    tests = xmlData.SparkDatalog.DutTestSessions.DutTestSession.TestResults;
    tests = tests(1).TestResult;
    sparkData = [];
    for i=1:length(tests)
        allData(i) = tests{i}.Attributes;
        metricName = matlab.lang.makeValidName(tests{i}.Attributes.MetricName);
        %metricName = strrep(tests{i}.Attributes.MetricName,' ','_');
        
        metricValue = tests{i}.Attributes.Value;
        metricValueD = str2double(metricValue);
        
        if isnan(metricValueD)
            sparkData.(metricName) = metricValue;
        else
            sparkData.(metricName) = metricValueD;
        end
    end
end
