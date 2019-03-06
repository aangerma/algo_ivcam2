calibfn =  'calibParams.xml';
calibParams = xml2structWrapper(calibfn);
sparkParams = calibParams.sparkParams;
s=Spark('','AlgoCalibration',sparkParams,@fprintf);
s.addTestProperty('CalibToolVersion',1.17)
s.startDUTsession('my_string');
s.addDTSproperty('TargetType','IRcalibrationChart');
s.AddMetrics('score', 99,1,100,true);
% s.endDUTsession([], true);
s.endDUTsession();
    