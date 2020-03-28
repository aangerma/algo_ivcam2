function data = getCalibDataFromCalPath(atcPath, accPath)

    %% ATC
    % Thermal
    shortTableFile                      = dir(fullfile(atcPath, 'Matlab', 'Algo_Thermal_Loop_Extra_CalibInfo_Ver*.bin'));
    shortCalibData                      = Calibration.tables.readCalibDataFromTableFile(fullfile(atcPath, 'Matlab', shortTableFile.name));
    data.tables.thermalShort            = shortCalibData.tmptrOffsetValuesShort;
    thermalTableFile                    = dir(fullfile(atcPath, 'Matlab', 'Algo_Thermal_Loop_CalibInfo_Ver*.bin'));
    thermalCalibData                    = Calibration.tables.readCalibDataFromTableFile(fullfile(atcPath, 'Matlab', thermalTableFile.name));
    data.tables.thermal                 = thermalCalibData.table;
    algoTableFile                       = dir(fullfile(atcPath, 'Matlab', 'Algo_Calibration_Info_CalibInfo_Ver*.bin'));
    algoCalibData                       = Calibration.tables.readCalibDataFromTableFile(fullfile(atcPath, 'Matlab', algoTableFile.name));
    data.regs.FRMW.atlMinVbias1         = algoCalibData.FRMW.atlMinVbias1;
    data.regs.FRMW.atlMaxVbias1         = algoCalibData.FRMW.atlMaxVbias1;
    data.regs.FRMW.atlMinVbias2         = algoCalibData.FRMW.atlMinVbias2;
    data.regs.FRMW.atlMaxVbias2         = algoCalibData.FRMW.atlMaxVbias2;
    data.regs.FRMW.atlMinVbias3         = algoCalibData.FRMW.atlMinVbias3;
    data.regs.FRMW.atlMaxVbias3         = algoCalibData.FRMW.atlMaxVbias3;
    % MEMS
    memsTableFile                       = dir(fullfile(atcPath, 'Matlab', 'MEMS_Electro_Optics_Calibration_Info_CalibInfo_Ver*.bin'));
    if ~isempty(memsTableFile)
        memsCalibData                   = Calibration.tables.readCalibDataFromTableFile(fullfile(atcPath, 'Matlab', memsTableFile.name));
        data.pzr.vSenseModel            = [memsCalibData.pzr(1).vsenseEstCoef, memsCalibData.pzr(3).vsenseEstCoef];
    else
        data.pzr.vSenseModel            = zeros(3,3,'single');
    end
    % DSM
    data.regs.FRMW.losAtMirrorRestHorz  = algoCalibData.FRMW.losAtMirrorRestHorz;
    data.regs.FRMW.losAtMirrorRestVert  = algoCalibData.FRMW.losAtMirrorRestVert;
    % Projection
    data.regs.FRMW.atlMinAngXL          = algoCalibData.FRMW.atlMinAngXL;
    data.regs.FRMW.atlMaxAngXL          = algoCalibData.FRMW.atlMaxAngXL;
    data.regs.FRMW.atlMinAngXR          = algoCalibData.FRMW.atlMinAngXR;
    data.regs.FRMW.atlMaxAngXR          = algoCalibData.FRMW.atlMaxAngXR;
    data.regs.FRMW.atlMinAngYU          = algoCalibData.FRMW.atlMinAngYU;
    data.regs.FRMW.atlMaxAngYU          = algoCalibData.FRMW.atlMaxAngYU;
    data.regs.FRMW.atlMinAngYB          = algoCalibData.FRMW.atlMinAngYB;
    data.regs.FRMW.atlMaxAngYB          = algoCalibData.FRMW.atlMaxAngYB;
    % Delays
    data.regs.EXTL.conLocDelayFastC     = algoCalibData.EXTL.conLocDelayFastC;
    data.regs.EXTL.conLocDelayFastF     = algoCalibData.EXTL.conLocDelayFastF;
    data.regs.EXTL.conLocDelaySlow      = algoCalibData.EXTL.conLocDelaySlow;
    data.regs.FRMW.conLocDelayFastSlope = algoCalibData.FRMW.conLocDelayFastSlope;
    data.regs.FRMW.conLocDelaySlowSlope = algoCalibData.FRMW.conLocDelaySlowSlope;
    % Readings
    data.regs.FRMW.dfzCalTmp            = algoCalibData.FRMW.dfzCalTmp;
    data.regs.FRMW.dfzApdCalTmp         = algoCalibData.FRMW.dfzApdCalTmp;
    data.regs.FRMW.dfzIbias             = algoCalibData.FRMW.dfzIbias;
    data.regs.FRMW.dfzVbias             = algoCalibData.FRMW.dfzVbias;
    finalCalcData                       = load(fullfile(atcPath, 'Matlab\mat_files\finalCalcAfterHeating_in.mat'));
    tempData                            = [finalCalcData.data.framesData.temp];
    data.heating.hum                    = [tempData.shtw2];
    data.heating.vBias                  = reshape([finalCalcData.data.framesData.vBias],3,[]);
    data.heating.iBias                  = reshape([finalCalcData.data.framesData.iBias],3,[]);
    
    %% ACC
    if exist(fullfile(accPath, 'Matlab', 'calibOutputFiles'), 'dir') % get data from tables
        algoCalibData                           = Calibration.tables.readCalibDataFromTableFile(fullfile(accPath, 'Matlab', 'calibOutputFiles', algoTableFile.name));
        % Readings
        data.regs.FRMW.dfzCalibrationLddTemp    = algoCalibData.FRMW.dfzCalibrationLddTemp;
        data.regs.FRMW.dfzCalibrationVddVal     = algoCalibData.FRMW.dfzCalibrationVddVal;
        % DFZ
        data.regs.DEST.txFRQpd                  = algoCalibData.DEST.txFRQpd;
        data.regs.FRMW.mirrorMovmentMode        = 1;
        data.regs.FRMW.xfov                     = algoCalibData.FRMW.xfov;
        data.regs.FRMW.yfov                     = algoCalibData.FRMW.yfov;
        data.regs.FRMW.projectionYshear         = algoCalibData.FRMW.projectionYshear;
        data.regs.FRMW.laserangleH              = algoCalibData.FRMW.laserangleH;
        data.regs.FRMW.laserangleV              = algoCalibData.FRMW.laserangleV;
        data.regs.FRMW.polyVars                 = algoCalibData.FRMW.polyVars;
        data.regs.FRMW.pitchFixFactor           = algoCalibData.FRMW.pitchFixFactor;
        data.regs.FRMW.undistAngHorz            = algoCalibData.FRMW.undistAngHorz;
        data.regs.FRMW.undistAngVert            = algoCalibData.FRMW.undistAngVert;
        data.regs.FRMW.fovexExistenceFlag       = algoCalibData.FRMW.fovexExistenceFlag;
        data.regs.FRMW.fovexNominal             = algoCalibData.FRMW.fovexNominal;
        data.regs.FRMW.fovexCenter              = algoCalibData.FRMW.fovexCenter;
        data.regs.FRMW.fovexLensDistFlag        = algoCalibData.FRMW.fovexLensDistFlag;
        data.regs.FRMW.fovexRadialK             = algoCalibData.FRMW.fovexRadialK;
        data.regs.FRMW.fovexTangentP            = algoCalibData.FRMW.fovexTangentP;
        tmp                                     = load(fullfile(accPath, 'Matlab\AlgoInternal\tpsUndistModel.mat'));
        data.tpsUndistModel                     = tmp.tpsUndistModel;
        % ROI
        data.regs.FRMW.calMarginL               = algoCalibData.FRMW.calMarginL;
        data.regs.FRMW.calMarginR               = algoCalibData.FRMW.calMarginR;
        data.regs.FRMW.calMarginT               = algoCalibData.FRMW.calMarginT;
        data.regs.FRMW.calMarginB               = algoCalibData.FRMW.calMarginB;
        % RTD over X/Y
        rtdOverXTableFile                       = dir(fullfile(accPath, 'Matlab', 'calibOutputFiles', 'Algo_rtdOverAngX_CalibInfo_Ver*.bin'));
        rtdOverXCalibData                       = Calibration.tables.readCalibDataFromTableFile(fullfile(accPath, 'Matlab', 'calibOutputFiles', rtdOverXTableFile.name));
        data.tables.rtdOverX                    = rtdOverXCalibData.table;
        rtdOverYTableFile                       = dir(fullfile(accPath, 'Matlab', 'calibOutputFiles', 'DEST_txPWRpd_Info_CalibInfo_Ver*.bin'));
        rtdOverYCalibData                       = Calibration.tables.readCalibDataFromTableFile(fullfile(accPath, 'Matlab', 'calibOutputFiles', rtdOverYTableFile.name));
        data.tables.rtdOverY                    = typecast(rtdOverYCalibData(9:end),'single');
        % RGB
        rgbTableFile                            = dir(fullfile(accPath, 'Matlab', 'calibOutputFiles', 'RGB_Calibration_Info_CalibInfo_Ver*.bin'));
        rgbCalibData                            = Calibration.tables.readCalibDataFromTableFile(fullfile(accPath, 'Matlab', 'calibOutputFiles', rgbTableFile.name));
        data.rgb.int.Kn                         = rgbCalibData.color.Kn;
        data.rgb.int.d                          = rgbCalibData.color.d;
        data.rgb.ext.r                          = rgbCalibData.extrinsics.r;
        data.rgb.ext.t                          = rgbCalibData.extrinsics.t;
        data.rgb.humCal                         = rgbCalibData.rgbCalTemperature;
        rgbThermalTableFile                     = dir(fullfile(accPath, 'Matlab', 'calibOutputFiles', 'RGB_Thermal_Info_CalibInfo_Ver*.bin'));
        rgbThermalCalibData                     = Calibration.tables.readCalibDataFromTableFile(fullfile(accPath, 'Matlab', 'calibOutputFiles', rgbThermalTableFile.name));
        data.tables.rgbThermal                  = rgbThermalCalibData.thermalTable;
    else % ATC didn't finish; get DFZ data from MAT files
        dfzOutput                               = load(fullfile(accPath, 'Matlab\mat_files\DFZ_Calib_Calc_out.mat'));
        % Readings
        data.regs.FRMW.dfzCalibrationLddTemp    = dfzOutput.dfzRegs.FRMW.dfzCalTmp;
        data.regs.FRMW.dfzCalibrationVddVal     = NaN;
        % DFZ
        data.regs.DEST.txFRQpd                  = dfzOutput.dfzRegs.DEST.txFRQpd;
        data.regs.FRMW.mirrorMovmentMode        = 1;
        data.regs.FRMW.xfov                     = dfzOutput.dfzRegs.FRMW.xfov;
        data.regs.FRMW.yfov                     = dfzOutput.dfzRegs.FRMW.yfov;
        data.regs.FRMW.projectionYshear         = dfzOutput.dfzRegs.FRMW.projectionYshear;
        data.regs.FRMW.laserangleH              = dfzOutput.dfzRegs.FRMW.laserangleH;
        data.regs.FRMW.laserangleV              = dfzOutput.dfzRegs.FRMW.laserangleV;
        data.regs.FRMW.polyVars                 = dfzOutput.dfzRegs.FRMW.polyVars;
        data.regs.FRMW.pitchFixFactor           = dfzOutput.dfzRegs.FRMW.pitchFixFactor;
        data.regs.FRMW.undistAngHorz            = dfzOutput.dfzRegs.FRMW.undistAngHorz;
        data.regs.FRMW.undistAngVert            = dfzOutput.dfzRegs.FRMW.undistAngVert;
        data.regs.FRMW.fovexExistenceFlag       = dfzOutput.dfzRegs.FRMW.fovexExistenceFlag;
        data.regs.FRMW.fovexNominal             = dfzOutput.dfzRegs.FRMW.fovexNominal;
        data.regs.FRMW.fovexCenter              = dfzOutput.dfzRegs.FRMW.fovexCenter;
        data.regs.FRMW.fovexLensDistFlag        = dfzOutput.dfzRegs.FRMW.fovexLensDistFlag;
        data.regs.FRMW.fovexRadialK             = dfzOutput.dfzRegs.FRMW.fovexRadialK;
        data.regs.FRMW.fovexTangentP            = dfzOutput.dfzRegs.FRMW.fovexTangentP;
        tmp                                     = load(fullfile(accPath, 'Matlab\AlgoInternal\tpsUndistModel.mat'));
        data.tpsUndistModel                     = tmp.tpsUndistModel;
        % ROI
        data.regs.FRMW.calMarginL               = NaN;
        data.regs.FRMW.calMarginR               = NaN;
        data.regs.FRMW.calMarginT               = NaN;
        data.regs.FRMW.calMarginB               = NaN;
        % RTD over X/Y
        data.tables.rtdOverX                    = NaN;
        data.tables.rtdOverY                    = NaN;
        % RGB
        data.rgb.int.Kn                         = NaN;
        data.rgb.int.d                          = NaN;
        data.rgb.ext.r                          = NaN;
        data.rgb.ext.t                          = NaN;
        data.rgb.humCal                         = NaN;
        data.tables.rgbThermal                  = NaN;
    end
    
end
