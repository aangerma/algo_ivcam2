function regs = getAlgoCalibDataFromBin(binFile)

fid = fopen(binFile, 'rb');
data = uint8(fread(fid));
fclose(fid);

fw = Firmware;
regs = fw.readAlgoEpromData(data);
