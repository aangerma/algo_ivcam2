close all
clear all
clc

%% data loading
dataIn = load('W:\BIG PBS\HENG-3317\F9340558\ACC1\Matlab\mat_files\DFZ_Calib_Calc_in.mat');
dataOut = load('W:\BIG PBS\HENG-3317\F9340558\ACC1\Matlab\mat_files\DFZ_Calib_Calc_out.mat');
load('W:\BIG PBS\HENG-3317\F9340558\ACC1\Matlab\AlgoInternal\verticesDFZ.mat', 'vertices')
load('W:\BIG PBS\HENG-3317\F9340558\ACC1\Matlab\AlgoInternal\tpsUndistModel.mat', 'tpsUndistModel')

%% regs definition
dataIn.DFZ_regs.DESTdepthAsRange        = logical(dataIn.DFZ_regs.DESTdepthAsRange);
dataIn.DFZ_regs.DIGGsphericalEn         = logical(dataIn.DFZ_regs.DIGGsphericalEn);
temp                                    = typecast(dataIn.DFZ_regs.DESTbaseline,'single');
dataIn.DFZ_regs.DESTbaseline            = temp(1);
dataIn.DFZ_regs.DESTbaseline2			= temp(2);
dataIn.DFZ_regs.GNRLzMaxSubMMExp        = uint16(dataIn.DFZ_regs.GNRLzMaxSubMMExp);
dataIn.DFZ_regs.DESTp2axa 				= typecast(dataIn.DFZ_regs.DESTp2axa,'single');
dataIn.DFZ_regs.DESTp2axb 				= typecast(dataIn.DFZ_regs.DESTp2axb,'single');
dataIn.DFZ_regs.DESTp2aya 				= typecast(dataIn.DFZ_regs.DESTp2aya,'single');
dataIn.DFZ_regs.DESTp2ayb 				= typecast(dataIn.DFZ_regs.DESTp2ayb,'single');
dataIn.DFZ_regs.DIGGsphericalOffset     = typecast(bitand(dataIn.DFZ_regs.DIGGsphericalOffset,hex2dec('0fffffff')),'int16');
dataIn.DFZ_regs.DIGGsphericalScale      = typecast(bitand(dataIn.DFZ_regs.DIGGsphericalScale ,hex2dec('0fff0fff')),'int16');
dataIn.DFZ_regs.DESThbaseline           = logical(dataIn.DFZ_regs.DESThbaseline);
dataIn.DFZ_regs.DESTtxFRQpd             = typecast(dataIn.DFZ_regs.DESTtxFRQpd,'single')'; %x3
dataIn.DFZ_regs.GNRLimgHsize            = uint16(dataIn.DFZ_regs.GNRLimgHsize);
dataIn.DFZ_regs.GNRLimgVsize            = uint16(dataIn.DFZ_regs.GNRLimgVsize);
dataIn.DFZ_regs.MTLBfastApprox(1)       = logical(dataIn.DFZ_regs.MTLBfastApprox(1));

fnames = fieldnames(dataIn.DFZ_regs);
for iField = 1:length(fnames)
    block = fnames{iField}(1:4);
    name = fnames{iField}(5:end);
    regsOrig.(block).(name) = dataIn.DFZ_regs.(fnames{iField});
end
regs = regsOrig;
blocks = fieldnames(dataOut.dfzRegs);
for iBlock = 1:length(blocks)
    regs.(blocks{iBlock}) = mergestruct(regs.(blocks{iBlock}), dataOut.dfzRegs.(blocks{iBlock}));
end

%% pre-processing
imSize = uint16([regs.GNRL.imgVsize, regs.GNRL.imgHsize]);
im = Calibration.aux.convertBytesToFrames(dataIn.frameBytes, imSize, [], true); 
nPoses = length(im);

rpt = zeros(560,3,nPoses);
for iIm = 1:nPoses
    fprintf('Processing pose #%d...\n', iIm);
    CB = CBTools.Checkerboard (im(iIm).i,'targetType', 'checkerboard_Iv2A1','imageRotatedBy180Flag',true, 'cornersDetectionThreshold', 0.2,'nonRectangleFlag',true);
    rpt(:,:,iIm) = Calibration.aux.samplePointsRtd(im(iIm).z, CB.getGridPointsMat, regsOrig, 0, CB.getColorMap, true);
end

%% sanity check
figure
for iIm = 1:nPoses
    rerunVertices = Utils.convert.RptToVertices(rpt(:,:,iIm), regs, tpsUndistModel);
    err = rerunVertices - vertices{iIm};
    subplot(1,nPoses,iIm), hold on
    for k = 1:3, cdfplot(err(:,k)), end
    grid on, xlabel('rerun error [mm]'), legend('x','y','z')
end

%% target generation
params.target.target = 'checkerboard_Iv2A1';
params.target.squareSize = 30; % [mm]
params.gridSize = [20, 28];
params.camera.K = [730.1642, 0, 541.5000; 0, 711.8812, 386.0000; 0, 0, 1]; % exemplary intrinsic matrix for XGA, utilized in DFZ eval

%% effect of uniform system delay
rtdErr = -10:0.2:9.5;
clear metrics
iIm = 1;
for iErr = 1:length(rtdErr)
    curRpt = rpt(:,:,iIm);
    curRpt(:,1) = curRpt(:,1) + rtdErr(iErr);
    in.vertices = Utils.convert.RptToVertices(curRpt, regs, tpsUndistModel);
    metrics(iErr) = GetGeomMetricsResults(in.vertices, params);
end
PlotMetricsVsError(metrics, rtdErr, 'RTD error [mm]')
sgtitle('Sensitivity to uniform RTD error')

%% effect of radial system delay
rtdErr = -4.1:0.1:3.8;
clear metrics
iIm = 1;
tempVertices = Utils.convert.RptToVertices(rpt(:,:,iIm), regs, tpsUndistModel);
ang = atand(sqrt(sum(tempVertices(:,1:2).^2,2)./tempVertices(:,3)));
%ang = atand(sqrt(tand(rpt(:,2,iIm)/2047*35).^2+tand(rpt(:,3,iIm)/2047*27).^2));
for iErr = 1:length(rtdErr)
    curRpt = rpt(:,:,iIm);
    curRpt(:,1) = curRpt(:,1) + rtdErr(iErr)*(ang(:)/35);
    in.vertices = Utils.convert.RptToVertices(curRpt, regs, tpsUndistModel);
    metrics(iErr) = GetGeomMetricsResults(in.vertices, params);
end
PlotMetricsVsError(metrics, rtdErr, 'RTD error at HFOV edge [mm]')
sgtitle('Sensitivity to radial RTD error')

%% effect of DSM scaling
xScaleErr = 0.986:0.001:1.013;
clear metrics
iIm = 1;
for iErr = 1:length(xScaleErr)
    curRpt = rpt(:,:,iIm);
    curRpt(:,2) = xScaleErr(iErr)*curRpt(:,2);
    in.vertices = Utils.convert.RptToVertices(curRpt, regs, tpsUndistModel);
    metrics(iErr) = GetGeomMetricsResults(in.vertices, params);
end
PlotMetricsVsError(metrics, xScaleErr, 'angx scale')
sgtitle('Sensitivity to DSM scaling')

yScaleErr = 0.979:0.002:1.020;
clear metrics
iIm = 1;
for iErr = 1:length(yScaleErr)
    curRpt = rpt(:,:,iIm);
    curRpt(:,3) = yScaleErr(iErr)*curRpt(:,3);
    in.vertices = Utils.convert.RptToVertices(curRpt, regs, tpsUndistModel);
    metrics(iErr) = GetGeomMetricsResults(in.vertices, params);
end
PlotMetricsVsError(metrics, yScaleErr, 'angy scale')
sgtitle('Sensitivity to DSM scaling')

%% effect of DSM shift
xShiftErr = -180:3:132;
clear metrics
iIm = 1;
for iErr = 1:length(xShiftErr)
    curRpt = rpt(:,:,iIm);
    curRpt(:,2) = curRpt(:,2) + xShiftErr(iErr);
    in.vertices = Utils.convert.RptToVertices(curRpt, regs, tpsUndistModel);
    metrics(iErr) = GetGeomMetricsResults(in.vertices, params);
end
PlotMetricsVsError(metrics, xShiftErr, 'angx shift')
sgtitle('Sensitivity to DSM shift')







