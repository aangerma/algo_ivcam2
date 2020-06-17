function [ac_table,rgbTable] = tablesFromDataMat(fname, outPath, writeToUnit)
    if ~exist('writeToUnit','var')
        writeToUnit = false;
    end
    testData = load(fname);   
    calTemp = 40;
    params.RGBImageSize =  testData.newParams.rgbRes;
    res =[];
    res.color.Kn = single(du.math.normalizeK(testData.newParams.Krgb,testData.newParams.rgbRes));
    res.color.d =  single(testData.newParams.rgbDistort);
    res.extrinsics.r = single(testData.newParams.Rrgb);
    res.extrinsics.t = single(testData.newParams.Trgb);
    RGBTable =  Calibration.rgb.buildRGBTable(res,params,calTemp);
    rgbTable = RGBTable.data;
    acDataOut = testData.dbg.acDataOut;
    flags = zeros(1,6,'uint8');
    flags(1:length(acDataOut.flags)) = acDataOut.flags;
    acDataOut.flags = flags;
    ac_table = Calibration.tables.convertCalibDataToBinTable(acDataOut, 'Algo_AutoCalibration');
    
    if exist('outPath','var')
        mkdirSafe(outPath)
        rgbFile = fullfile(outPath,'RGB_Calibration_Info_CalibInfo_Ver_00_48.bin');
        acFile = fullfile(outPath,'Algo_AutoCalibration_CalibInfo_Ver_01_00.bin');
        writeAllBytes(rgbTable,rgbFile);
        writeAllBytes(ac_table,acFile);
    end
    if writeToUnit
        hw = HWinterface;
        hw.cmd(sprintf('WrCalibInfo "%s"',acFile));
        hw.cmd(sprintf('WrCalibInfo "%s"',rgbFile));
    end
end

