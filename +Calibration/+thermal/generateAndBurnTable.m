function generateAndBurnTable(hw,eepromRegs, table,calibParams,runParams,fprintff,calibPassed,data,calib_dir)
% Creates a binary table as requested

dsmTable = table(:,1:4);
rtdTable = table(:,5);
dsmTable = uint16(dsmTable*2^8);
rtdTable = typecast(int16(rtdTable*2^8),'uint16');
tableShifted = [dsmTable,rtdTable]; % FW expected format

thermalTableFileName = Calibration.aux.genTableBinFileName('Algo_Thermal_Loop_CalibInfo', calibParams.tableVersions.algoThermal);
thermalTableFullPath = fullfile(runParams.outputFolder, thermalTableFileName);

algoTableName = Calibration.aux.genTableBinFileName('Algo_Calibration_Info_CalibInfo', calibParams.tableVersions.algoCalib);
algoTableFileName = fullfile(runParams.outputFolder, algoTableName);

Calibration.thermal.saveThermalTable( tableShifted , thermalTableFullPath );
fprintff('Generated algo thermal table full path:\n%s\n',thermalTableFullPath);
initFldr = fullfile(fileparts(fileparts(mfilename('fullpath'))),'releaseConfigCalibVGA');
%fw = Pipe.loadFirmware(initFldr);
if(exist(fullfile(calib_dir , 'regsDefinitions.frmw'), 'file') == 2)
    fw = Pipe.loadFirmware(initFldr,'tablesFolder',calib_dir); % incase of DLL assume table same folder as fnCalib
else
    fw = Pipe.loadFirmware(initFldr); % use default path of table folder
end

eepromRegs.FRMW.atlMinVbias1 = single(data.tableResults.angx.p0(1));
eepromRegs.FRMW.atlMaxVbias1 = single(data.tableResults.angx.p1(1));
eepromRegs.FRMW.atlMinVbias2 = single(data.tableResults.angy.minval);
eepromRegs.FRMW.atlMaxVbias2 = single(data.tableResults.angy.maxval);
eepromRegs.FRMW.atlMinVbias3 = single(data.tableResults.angx.p0(2));
eepromRegs.FRMW.atlMaxVbias3 = single(data.tableResults.angx.p1(2));

fw.setRegs(eepromRegs,'');
fw.get();
fw.generateTablesForFw(runParams.outputFolder,1,[],calibParams.tableVersions);

if calibPassed && ~isempty(hw)
    fprintff('Burning algo thermal table...');
    try 
        cmdstr = sprintf('WrCalibInfo %s',thermalTableFileName);
        hw.cmd(cmdstr);
        fprintff('Done\n');
    catch
        fprintf('Failed to write Algo_Thermal_Table to EPROM. You are probably using an unsupported fw version.\n');
    end
    fprintff('Burning algo calibration table...');
    try
        cmdstr = sprintf('WrCalibInfo %s',algoTableFileName);
        hw.cmd(cmdstr);
        fprintff('Done\n');
    catch
        fprintf('Failed to write Algo_Calibration_Info to EPROM. You are probably using an unsupported fw version.\n');
    end
     
end

end


function writeMWD(d,fn,nMax,PL_SZ)

n = ceil(size(d,1)/PL_SZ);
if(n>nMax)
    error('error, too many registers to write!');
end
for i=1:nMax
    fid = fopen(sprintf(strrep(fn,'\','\\'),i),'w');
    ibeg = (i-1)*PL_SZ+1;
    iend = min(i*PL_SZ,size(d,1));
    if(i<=n)
        di=d(ibeg:iend,:)';
        fprintf(fid,'mwd %08x %08x // %s\n',di{:});
    else
        fprintf(fid,'mwd a00e0870 00000000 // DO NOTHING\n');%prevent empty file
    end
    fclose(fid);
end

end
