fw = Firmware;
calibPath = '\\143.185.124.250\tester data\IDC Data\IVCAM\L515\Calibration\BIG PBS\FW 1.3.0.100 - sanity\F9240028- ALGO1+2\ALGO1 3.04 - no RGB, fail VAL';
fw.writeDynamicRangeTable(fullfile(calibPath,'Dynamic_Range_Info_CalibInfo_Ver_05_04.bin'),'\\143.185.124.250\tester data\IDC Data\IVCAM\L515\Calibration\BIG PBS\FW 1.3.0.100 - sanity\F9240028- ALGO1+2\ALGO1 3.04 - no RGB, fail VAL\correctPresets');
