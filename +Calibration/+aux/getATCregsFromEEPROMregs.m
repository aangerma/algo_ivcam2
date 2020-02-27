function [delayRegs, dsmRegs, thermalRegs, dfzRegs] = getATCregsFromEEPROMregs(eepromRegs, dfzRegs)
    delayRegs.EXTL.conLocDelaySlow      = eepromRegs.EXTL.conLocDelaySlow;
    delayRegs.EXTL.conLocDelayFastC     = eepromRegs.EXTL.conLocDelayFastC;
    delayRegs.EXTL.conLocDelayFastF     = eepromRegs.EXTL.conLocDelayFastF;
    delayRegs.FRMW.conLocDelaySlowSlope = eepromRegs.FRMW.conLocDelaySlowSlope;
    delayRegs.FRMW.conLocDelayFastSlope = eepromRegs.FRMW.conLocDelayFastSlope;
    
    dsmRegs.EXTL.dsmXscale              = eepromRegs.EXTL.dsmXscale;
    dsmRegs.EXTL.dsmXoffset             = eepromRegs.EXTL.dsmXoffset;
    dsmRegs.EXTL.dsmYscale              = eepromRegs.EXTL.dsmYscale;
    dsmRegs.EXTL.dsmYoffset             = eepromRegs.EXTL.dsmYoffset;
    dsmRegs.FRMW.losAtMirrorRestHorz    = eepromRegs.FRMW.losAtMirrorRestHorz;
    dsmRegs.FRMW.losAtMirrorRestVert    = eepromRegs.FRMW.losAtMirrorRestVert;
    
    thermalRegs.FRMW.atlMinVbias1       = eepromRegs.FRMW.atlMinVbias1;
    thermalRegs.FRMW.atlMaxVbias1       = eepromRegs.FRMW.atlMaxVbias1;
    thermalRegs.FRMW.atlMinVbias2       = eepromRegs.FRMW.atlMinVbias2;
    thermalRegs.FRMW.atlMaxVbias2       = eepromRegs.FRMW.atlMaxVbias2;
    thermalRegs.FRMW.atlMinVbias3       = eepromRegs.FRMW.atlMinVbias3;
    thermalRegs.FRMW.atlMaxVbias3       = eepromRegs.FRMW.atlMaxVbias3;
    thermalRegs.FRMW.atlMinAngXL        = eepromRegs.FRMW.atlMinAngXL;
    thermalRegs.FRMW.atlMinAngXR        = eepromRegs.FRMW.atlMinAngXR;
    thermalRegs.FRMW.atlMaxAngXL        = eepromRegs.FRMW.atlMaxAngXL;
    thermalRegs.FRMW.atlMaxAngXR        = eepromRegs.FRMW.atlMaxAngXR;
    thermalRegs.FRMW.atlMinAngYU        = eepromRegs.FRMW.atlMinAngYU;
    thermalRegs.FRMW.atlMinAngYB        = eepromRegs.FRMW.atlMinAngYB;
    thermalRegs.FRMW.atlMaxAngYU        = eepromRegs.FRMW.atlMaxAngYU;
    thermalRegs.FRMW.atlMaxAngYB        = eepromRegs.FRMW.atlMaxAngYB;
    thermalRegs.FRMW.atlMaCalTmp        = eepromRegs.FRMW.atlMaCalTmp;
    thermalRegs.FRMW.atlSlopeMA         = eepromRegs.FRMW.atlSlopeMA;
    thermalRegs.FRMW.humidApdTempDiff   = eepromRegs.FRMW.humidApdTempDiff;
    
    dfzRegs.FRMW.dfzCalTmp              = eepromRegs.FRMW.dfzCalTmp;
    dfzRegs.FRMW.dfzApdCalTmp           = eepromRegs.FRMW.dfzApdCalTmp;
    dfzRegs.FRMW.dfzVbias               = eepromRegs.FRMW.dfzVbias;
    dfzRegs.FRMW.dfzIbias               = eepromRegs.FRMW.dfzIbias;
end