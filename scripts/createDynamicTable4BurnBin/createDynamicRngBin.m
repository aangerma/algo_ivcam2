% Take from ...\ACC\Matlab\AlgoInternal the longRangePreset.csv and the
% shortRangePreset.csv files, copy them and then change to the desired
% value. presetsPath parameter will point to where they are

presetsPath = '\\143.185.124.250\Tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-2900\F9441134\ACC1-3.21.0.0\Matlab\AlgoInternal\ModRef44VGA';
calibParams = xml2structWrapper('D:\worksapce\ivcam2\algo_ivcam2\Tools\CalibTools\AlgoCameraCalibration\calibParamsVXGA.xml');
presetsTableFileName = Calibration.aux.genTableBinFileName('Dynamic_Range_Info_CalibInfo', calibParams.tableVersions.dynamicRange);
fw = Firmware;
fw.writeDynamicRangeTable(fullfile(presetsPath, presetsTableFileName),presetsPath);
