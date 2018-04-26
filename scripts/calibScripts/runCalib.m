params.init = false;
params.outputFolder='C:\Temp\v0426';
params.coarseIrDelay = true;
params.fineIrDelay = true;
params.coarseDepthDelay = true;
params.fineDepthDelay = true;
params.verbose = true;
Calibration.runCalibStream(params, @fprintf)

