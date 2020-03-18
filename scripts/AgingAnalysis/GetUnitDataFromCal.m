function unitData = GetUnitDataFromCal(atcPath, accPath, tableVersions, calVersion)

    %% ATC
    % Thermal
    shortTableName                   = sprintf('Algo_Thermal_Loop_Extra_CalibInfo_Ver_%02d_%02d.bin', tableVersions.algoThermalExtras, calVersion);
    shortTableBin                    = fullfile(atcPath, 'Matlab', shortTableName);
    shortCalibData                   = Calibration.tables.readCalibDataFromTableFile(shortTableBin);
    unitData.thermal.tableShort      = shortCalibData.tmptrOffsetValuesShort;
    thermalTableName                 = sprintf('Algo_Thermal_Loop_CalibInfo_Ver_%02d_%02d.bin', tableVersions.algoThermal, calVersion);
    thermalTableBin                  = fullfile(atcPath, 'Matlab', thermalTableName);
    thermalCalibData                 = Calibration.tables.readCalibDataFromTableFile(thermalTableBin);
    unitData.thermal.table           = thermalCalibData.table;
    algoTableName                    = sprintf('Algo_Calibration_Info_CalibInfo_Ver_%02d_%02d.bin', tableVersions.algoCalib, calVersion);
    algoTableBin                     = fullfile(atcPath, 'Matlab', algoTableName);
    algoCalibData                    = Calibration.tables.readCalibDataFromTableFile(algoTableBin);
    unitData.thermal.v2Lims          = [algoCalibData.FRMW.atlMinVbias2, algoCalibData.FRMW.atlMaxVbias2];
    unitData.thermal.v13Lims         = [algoCalibData.FRMW.atlMinVbias1, algoCalibData.FRMW.atlMaxVbias1; algoCalibData.FRMW.atlMinVbias3, algoCalibData.FRMW.atlMaxVbias3];
    % MEMS
    if (calVersion>=47)
        memsTableName                = sprintf('MEMS_Electro_Optics_Calibration_Info_CalibInfo_Ver_%02d_%02d.bin', floor(tableVersions.mems), round(100*mod(tableVersions.mems,1)));
        memsTableBin                 = fullfile(atcPath, 'Matlab', memsTableName);
        memsCalibData                = Calibration.tables.readCalibDataFromTableFile(memsTableBin);
        unitData.pzr.vSenseModel     = [memsCalibData.pzr(1).vsenseEstCoef, memsCalibData.pzr(2).vsenseEstCoef, memsCalibData.pzr(3).vsenseEstCoef];
    else
        unitData.pzr.vSenseModel     = zeros(3,3,'single');
    end
    % DSM
    unitData.dsm                     = getDsmDataFromCal(fullfile(atcPath, 'Matlab\mat_files\DSM_Calib_Calc_in.mat'));
    unitData.dsm.xScale              = algoCalibData.EXTL.dsmXscale;
    unitData.dsm.xOffset             = algoCalibData.EXTL.dsmXoffset;
    unitData.dsm.yScale              = algoCalibData.EXTL.dsmYscale;
    unitData.dsm.yOffset             = algoCalibData.EXTL.dsmYoffset;
    unitData.dsm.losAtMirrorRest     = [algoCalibData.FRMW.losAtMirrorRestHorz, algoCalibData.FRMW.losAtMirrorRestVert];
    % Projection
    unitData.proj.leftLims           = [algoCalibData.FRMW.atlMinAngXL, algoCalibData.FRMW.atlMaxAngXL];
    unitData.proj.rightLims          = [algoCalibData.FRMW.atlMinAngXR, algoCalibData.FRMW.atlMaxAngXR];
    unitData.proj.topLims            = [algoCalibData.FRMW.atlMinAngYU, algoCalibData.FRMW.atlMaxAngYU];
    unitData.proj.bottomLims         = [algoCalibData.FRMW.atlMinAngYB, algoCalibData.FRMW.atlMaxAngYB];
    % Delays
    unitData.delays.zOffset          = algoCalibData.EXTL.conLocDelayFastC+algoCalibData.EXTL.conLocDelayFastF;
    unitData.delays.irOffset         = uint32(int32(unitData.delays.zOffset)-int32(mod(algoCalibData.EXTL.conLocDelaySlow,2^31)));
    unitData.delays.zSlope           = algoCalibData.FRMW.conLocDelayFastSlope;
    unitData.delays.irSlope          = algoCalibData.FRMW.conLocDelaySlowSlope;
    % Readings
    unitData.sensors.lddRef          = algoCalibData.FRMW.dfzCalTmp;
    unitData.sensors.apdRef          = algoCalibData.FRMW.dfzApdCalTmp;
    unitData.sensors.iBiasRef        = algoCalibData.FRMW.dfzIbias;
    unitData.sensors.vBiasRef        = algoCalibData.FRMW.dfzVbias;
    finalCalcData                    = load(fullfile(atcPath, 'Matlab\mat_files\finalCalcAfterHeating_in.mat'));
    tempData                         = [finalCalcData.data.framesData.temp];
    unitData.sensors.humThermal      = [tempData.shtw2];
    unitData.sensors.vBiasThermal    = reshape([finalCalcData.data.framesData.vBias],3,[]);
    unitData.sensors.iBiasThermal    = reshape([finalCalcData.data.framesData.iBias],3,[]);
    
    %% ACC
    algoTableBin                     = fullfile(accPath, 'Matlab', 'calibOutputFiles', algoTableName);
    algoCalibData                    = Calibration.tables.readCalibDataFromTableFile(algoTableBin);
    % Readings
    unitData.sensors.lddDFZ          = algoCalibData.FRMW.dfzCalibrationLddTemp;
    unitData.sensors.vddDFZ          = algoCalibData.FRMW.dfzCalibrationVddVal;
    % DFZ
    unitData.dfz.fov                 = [algoCalibData.FRMW.xfov, algoCalibData.FRMW.yfov];
    unitData.dfz.laserAngle          = [algoCalibData.FRMW.laserangleH, algoCalibData.FRMW.laserangleV];
    unitData.dfz.systemDelay         = algoCalibData.DEST.txFRQpd;
    unitData.dfz.pitchFixFactor      = algoCalibData.FRMW.pitchFixFactor;
    unitData.dfz.polyVar             = algoCalibData.FRMW.polyVars(2);
    unitData.dfz.fineCorrHorz        = algoCalibData.FRMW.undistAngHorz;
    unitData.dfz.tpsModel            = load(fullfile(accPath, 'Matlab\AlgoInternal\tpsUndistModel.mat'));
    % ROI
    unitData.roi.xMargins            = [algoCalibData.FRMW.calMarginL, algoCalibData.FRMW.calMarginR];
    unitData.roi.yMargins            = [algoCalibData.FRMW.calMarginT, algoCalibData.FRMW.calMarginB];
    % Undist
    load('memordInv.mat', 'memordInv')
    unitData.undist.offset           = [algoCalibData.DIGG.undistX0, algoCalibData.DIGG.undistY0];
    unitData.undist.scale            = [algoCalibData.DIGG.undistFx, algoCalibData.DIGG.undistFy];
    undistTableName1                 = sprintf('DIGG_Undist_Info_1_CalibInfo_Ver_%02d_%02d.bin', tableVersions.diggUndist, calVersion);
    undistTableBin1                  = fullfile(accPath, 'Matlab', 'calibOutputFiles', undistTableName1);
    undistCalibData1                 = Calibration.tables.readCalibDataFromTableFile(undistTableBin1);
    undistTableName2                 = sprintf('DIGG_Undist_Info_2_CalibInfo_Ver_%02d_%02d.bin', tableVersions.diggUndist, calVersion);
    undistTableBin2                  = fullfile(accPath, 'Matlab', 'calibOutputFiles', undistTableName2);
    undistCalibData2                 = Calibration.tables.readCalibDataFromTableFile(undistTableBin2);
    undistTableName3                 = sprintf('DIGG_Gamma_Info_CalibInfo_Ver_%02d_%02d.bin', tableVersions.diggGamma, calVersion);
    undistTableBin3                  = fullfile(accPath, 'Matlab', 'calibOutputFiles', undistTableName3);
    undistCalibData3                 = Calibration.tables.readCalibDataFromTableFile(undistTableBin3);
    undistTable                      = typecast([undistCalibData1(9:end); undistCalibData2(9:end); undistCalibData3(149:end)],'uint32');
    undistTable                      = undistTable(memordInv);
    unitData.undist.x                = reshape(undistTable(1:2:end),32,32);
    unitData.undist.y                = reshape(undistTable(2:2:end),32,32);
    % RTD over X/Y
    rtdOverXTableName                = sprintf('Algo_rtdOverAngX_CalibInfo_Ver_%02d_%02d.bin', tableVersions.algoRtdOverAngX, calVersion);
    rtdOverXTableBin                 = fullfile(accPath, 'Matlab', 'calibOutputFiles', rtdOverXTableName);
    rtdOverXCalibData                = Calibration.tables.readCalibDataFromTableFile(rtdOverXTableBin);
    unitData.dfz.rtdOverX            = rtdOverXCalibData.table;
    rtdOverYTableName                = sprintf('DEST_txPWRpd_Info_CalibInfo_Ver_%02d_%02d.bin', tableVersions.destTxPwrPd, calVersion);
    rtdOverYTableBin                 = fullfile(accPath, 'Matlab', 'calibOutputFiles', rtdOverYTableName);
    rtdOverYCalibData                = Calibration.tables.readCalibDataFromTableFile(rtdOverYTableBin);
    unitData.dfz.rtdOverY            = typecast(rtdOverYCalibData(9:end),'single');
    % RGB
    rgbTableName                     = sprintf('RGB_Calibration_Info_CalibInfo_Ver_%02d_%02d.bin', tableVersions.rgbCalib, calVersion);
    rgbTableBin                      = fullfile(accPath, 'Matlab', 'calibOutputFiles', rgbTableName);
    rgbCalibData                     = Calibration.tables.readCalibDataFromTableFile(rgbTableBin);
    unitData.rgb.int.Kn              = rgbCalibData.color.Kn;
    unitData.rgb.int.d               = rgbCalibData.color.d;
    unitData.rgb.ext.r               = rgbCalibData.extrinsics.r;
    unitData.rgb.ext.t               = rgbCalibData.extrinsics.t;
    unitData.rgb.humCal              = rgbCalibData.rgbCalTemperature;
    rgbThermalTableName              = sprintf('RGB_Thermal_Info_CalibInfo_Ver_%02d_%02d.bin', tableVersions.algoRgbThermal, calVersion);
    rgbThermalTableBin               = fullfile(accPath, 'Matlab', 'calibOutputFiles', rgbThermalTableName);
    rgbThermalCalibData              = Calibration.tables.readCalibDataFromTableFile(rgbThermalTableBin);
    unitData.rgb.thermalTable        = rgbThermalCalibData.thermalTable;
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function dsmData = getDsmDataFromCal(dsmCalFile)
    %sz, dsmregs_current, calibParams
    %im, sz, dsmregs_current, calibParams
    load(dsmCalFile);
    axDim = double(flip(sz));
    IR_image = Calibration.aux.average_images(Calibration.aux.convertBytesToFrames(frameBytes, sz, [], false).i);
    angxRawZO = median(vec(angxRawZOVec));
    angyRawZO = median(vec(angyRawZOVec));
    
    params = struct('dsmXscale', dsmregs_current.Xscale, 'dsmXoffset', dsmregs_current.Xoffset, 'dsmYscale', dsmregs_current.Yscale, 'dsmYoffset', dsmregs_current.Yoffset);
    [angxZO, angyZO] = Calibration.aux.transform.applyDsm(angxRawZO, angyRawZO, params, 'direct');
    
    colZO = uint16(round((1 + angxZO/2047)/2*(axDim(1)-1)+1));
    rowZO = uint16(round((1 + angyZO/2047)/2*(axDim(2)-1)+1));
    for ax = 1:2
        if ax == 1
            vCenter =  IR_image(rowZO,:) > 0;
            angmin(ax) = ((find(sum(vCenter,ax),1,'first'))-1-(axDim(ax)-1)/2)/((axDim(ax)-1)/2)*2047;
        else
            vAll =  IR_image > 0;
            vCenter =  IR_image(:,colZO) > 0;
            angmin(ax) = ((find(sum(vAll,ax),1,'first'))-1-(axDim(ax)-1)/2)/((axDim(ax)-1)/2)*2047;
        end
        angmax(ax) = ((find(sum(vCenter,ax),1,'last' ))-1-(axDim(ax)-1)/2)/((axDim(ax)-1)/2)*2047;
    end
    dsmData.xLims = [angmin(1), angmax(1)];
    dsmData.yLims = [angmin(2), angmax(2)];
end


