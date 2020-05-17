function robotAc2CameraErrorInject(hFactor, vFactor, hOffset, vOffset)
    mFile = mfilename('fullpath')
    mFileParts = strsplit(mFile, '\')
    filePath = fullfile(mFileParts{1:end-2},'onlineCalibration\Algo_AutoCalibration_CalibInfo_Ver_03_15.bin')
    if ~exist(filePath)
        sprintf('cant find file: %s', filePath)
    end
    fid=fopen(filePath,'rb');
    binTable=fread(fid,Inf,'*uint8');
    fclose(fid);
    acData = Calibration.tables.convertBinTableToCalibData(binTable,'Algo_AutoCalibration');
    
    
    if exist('hFactor','var')
        acData.hFactor = hFactor;
    end
    if exist('vFactor','var')
        acData.vFactor = vFactor;
    end
    if exist('hOffset','var')
        acData.hOffset = hOffset;
    end
    if exist('vOffset','var')
        acData.vOffset = vOffset;
    end
    
    binTable = Calibration.tables.convertCalibDataToBinTable(acData, 'Algo_AutoCalibration');
    binFilePath = fullfile(mFileParts{1:end-2},'onlineCalibration\Algo_AutoCalibration_CalibInfo_Ver_03_16.bin')
    writeAllBytes(binTable, binFilePath);
    hw = HWinterface()
    hw.cmd(sprintf('WrCalibInfo %s',  binFilePath))

    
end