calibfn =  'calibParams.xml';
calibParams = xml2structWrapper(calibfn);
sparkFolders = 'C:\source\algo_ivcam2\scripts\IV2calibTool';
s=Spark('Algo','AlgoCalibration',sparkFolders);
s.addTestProperty('CalibVersion',113)
s.startDUTsession('my_string');
s.addDTSproperty('TargetType','IRcalibrationChart');


s.AddMetrics('score', 99,calibParams.passScore,100,true);
% s.endDUTsession([], true);
s.endDUTsession();
    