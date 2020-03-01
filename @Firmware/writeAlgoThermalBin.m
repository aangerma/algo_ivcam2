function [] = writeAlgoThermalBin(obj,fname)

EXTLdsmXscale = obj.getAddrData('EXTLdsmXscale');
EXTLdsmYscale = obj.getAddrData('EXTLdsmYscale');
EXTLdsmXoffset = obj.getAddrData('EXTLdsmXoffset');
EXTLdsmYoffset = obj.getAddrData('EXTLdsmYoffset');
DESTtmptrOffset = obj.getAddrData('DESTtmptrOffset');

table = typecast([EXTLdsmXscale{2},EXTLdsmYscale{2},EXTLdsmXoffset{2},EXTLdsmYoffset{2},DESTtmptrOffset{2}],'single');

calibData = struct('table', repmat(table, 48, 1));
binTable = Calibration.tables.convertCalibDataToBinTable(calibData, 'Algo_Thermal_Loop_CalibInfo');
writeAllBytes(binTable, fname);

end

