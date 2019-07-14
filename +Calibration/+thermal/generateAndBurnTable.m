function generateAndBurnTable(hw,eepromRegs, table,calibParams,runParams,fprintff,calibPassed,data,calib_dir)
% Creates a binary table as requested

tableShifted = int16(table * 2^8); % FW expected format


version = typecast(eepromRegs.FRMW.calibVersion,'single');
whole = floor(version);
frac = mod(version*100,100);

calibpostfix = sprintf('_Ver_%02d_%02d',whole,frac);

calibParams.fwTable.name = [calibParams.fwTable.name,calibpostfix,'.bin'];
tableName = fullfile(runParams.outputFolder,calibParams.fwTable.name);
Calibration.thermal.saveThermalTable( tableShifted , tableName );
fprintff('Generated algo thermal table full path:\n%s\n',tableName);
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
fw.generateTablesForFw(runParams.outputFolder,1);

if calibPassed && ~isempty(hw)
    fprintff('Burning algo thermal table...');
    try 
        cmdstr = sprintf('WrCalibInfo %s',tableName);
        hw.cmd(cmdstr);
        fprintff('Done\n');
    catch
        fprintf('Failed to write Algo_Thermal_Table to EPROM. You are probably using an unsupported fw version.\n');
    end
    fprintff('Burning algo calibration table...');
    try
        algoCalibInfoName = fullfile(calibOutput,['Algo_Calibration_Info_CalibInfo',calibpostfix,'.bin']);
        cmdstr = sprintf('WrCalibInfo %s',algoCalibInfoName);
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
