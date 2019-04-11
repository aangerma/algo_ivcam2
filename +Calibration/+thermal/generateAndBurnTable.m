function generateAndBurnTable(hw,table,calibParams,runParams,fprintff,calibPassed)
% Creates a binary table as requested

tableShifted = int16(table * 2^8); % FW expected format


version = thermalCalibToolVersion;
whole = floor(version);
frac = floor(mod(version,1)*100);

calibpostfix = sprintf('_Ver_%02d_%02d.bin',whole,frac);

calibParams.fwTable.name = [calibParams.fwTable.name,calibpostfix];
tableName = fullfile(runParams.outputFolder,calibParams.fwTable.name);
Calibration.thermal.saveThermalTable( tableShifted , tableName );
fprintff('Generated algo thermal table full path:\n%s\n',tableName);
if calibPassed
    fprintff('Burning algo thermal table...');
    try 
        cmdstr = sprintf('WrCalibInfo %s',tableName);
        hw.cmd(cmdstr);
        fprintff('Done\n');
    catch
        fprintf('Failed to write Algo_Thermal_Table to EPROM. You are probably using an unsupported fw version.\n');
    end
end

end
