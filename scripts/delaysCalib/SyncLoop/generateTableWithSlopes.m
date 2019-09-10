% Info for F9280051
IR_slope    = 0.94;
IR_offset   = 98310.7;
Z_slope     = 0.81;
Z_offset    = 98432.9;

% FW regs generation
fw = Pipe.loadFirmware('W:\BIG PBS\HENG-2456\F9280051\Algo1 3.07.0\AlgoInternal');
fw.setRegs('FRMWconLocDelaySlowSlope',single(IR_slope))
fw.setRegs('FRMWconLocDelayFastSlope',single(Z_slope))
regs = fw.get();

% Updated unit info
IR_delay = round(IR_offset + IR_slope*regs.FRMW.dfzCalTmp); % T_ref = 54.2363663
Z_delay = round(Z_offset + Z_slope*regs.FRMW.dfzCalTmp);
fw.setRegs('EXTLconLocDelayFastC', uint32(8*floor(Z_delay/8))) % 98472
fw.setRegs('EXTLconLocDelayFastF', uint32(mod(Z_delay,8))) % 5
fw.setRegs('EXTLconLocDelaySlow', uint32(2^31)+uint32(Z_delay-IR_delay)) % 2147483763 (115)

outputFldr = pwd;
EPROMtable = generateTablesForFw(fw, outputFldr, true);
