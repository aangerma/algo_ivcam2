close all
clear all
clc

%% regs definition
regs.FRMW.laserangleH = 0;
regs.FRMW.laserangleV = 0;

regs.FRMW.fovexExistenceFlag = 1;
regs.FRMW.fovexNominal = [0.0807405, 0.0030212, -0.0001276, 0.0000036];
regs.FRMW.fovexCenter = [0, 0];
regs.FRMW.fovexLensDistFlag = 0;
regs.FRMW.fovexRadialK = [0, 0, 0];
regs.FRMW.fovexTangentP = [0 0];

regs.DEST.baseline = -10;
regs.DEST.baseline2 = regs.DEST.baseline^2;

%% target generation
params.target.target = 'checkerboard_Iv2A1';
params.target.squareSize = 30; % [mm]
params.gridSize = [20, 28];

yGrid = (1:params.gridSize(1))*params.target.squareSize;
yGrid = yGrid - mean(yGrid);
xGrid = (1:params.gridSize(2))*params.target.squareSize;
xGrid = xGrid - mean(xGrid);
[y, x] = ndgrid(yGrid, xGrid);
nanify = true(params.gridSize);
nanify(2:end-1, 2:end-1) = false;
x(nanify) = NaN;
y(nanify) = NaN;

z = 600*ones(size(x));
z(nanify) = NaN;
in.vertices = [x(:), y(:), z(:)];

%% metrics sanity
params.camera.K = [1024/2/tand(35), 0, 1024/2; 0, 768/2/tand(27), 768/2; 0, 0, 1]; % an "ideal" intrinsic matrix for XGA
metrics = GetGeomMetricsResults(in.vertices, params);

%% effect of uniform system delay
rtdErr = -10:0.2:10;
clear metrics
for iErr = 1:length(rtdErr)
    out = Utils.convert.SphericalToCartesian(in, regs, 'inverse');
    out.rtd = out.rtd + rtdErr(iErr);
    inNew = Utils.convert.SphericalToCartesian(out, regs, 'direct');
    metrics(iErr) = GetGeomMetricsResults(inNew.vertices, params);
end
PlotMetricsVsError(metrics, rtdErr, 'RTD error [mm]')
sgtitle('Sensitivity to uniform RTD error')

%% effect of radial system delay
rtdErr = -4.1:0.1:4.1;
ang = atand(sqrt(sum(in.vertices(:,1:2).^2,2)./in.vertices(:,3)));
clear metrics
for iErr = 1:length(rtdErr)
    out = Utils.convert.SphericalToCartesian(in, regs, 'inverse');
    out.rtd = out.rtd + rtdErr(iErr).*(ang(:)/35);
    inNew = Utils.convert.SphericalToCartesian(out, regs, 'direct');
    metrics(iErr) = GetGeomMetricsResults(inNew.vertices, params);
end
PlotMetricsVsError(metrics, rtdErr, 'RTD error at HFOV edge [mm]')
sgtitle('Sensitivity to radial RTD error')

%% effect of LOS scaling
xScaleErr = 0.988:0.001:1.012;
clear metrics
for iErr = 1:length(xScaleErr)
    out = Utils.convert.SphericalToCartesian(in, regs, 'inverse');
    out.angx = xScaleErr(iErr)*out.angx;
    inNew = Utils.convert.SphericalToCartesian(out, regs, 'direct');
    metrics(iErr) = GetGeomMetricsResults(inNew.vertices, params);
end
PlotMetricsVsError(metrics, xScaleErr, 'angx scale [1/\circ]')
sgtitle('Sensitivity to LOS scaling')

%% effect of LOS shift
xShiftErr = -4.4:0.1:4.4;
clear metrics
for iErr = 1:length(xShiftErr)
    out = Utils.convert.SphericalToCartesian(in, regs, 'inverse');
    out.angx = out.angx + xShiftErr(iErr);
    inNew = Utils.convert.SphericalToCartesian(out, regs, 'direct');
    metrics(iErr) = GetGeomMetricsResults(inNew.vertices, params);
end
PlotMetricsVsError(metrics, xShiftErr, 'angx shift [\circ]')
sgtitle('Sensitivity to LOS shift')







