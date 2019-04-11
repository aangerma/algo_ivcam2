load('validationData.mat');
tableRange = [32,79]; % Or 35-66, according the calibParams.xml that was used - only 1.21.5_DeveloperVersion is 32-79.
errors = Calibration.thermal.calcThermalScores(data,calibParams.fwTable.tempBinRange);