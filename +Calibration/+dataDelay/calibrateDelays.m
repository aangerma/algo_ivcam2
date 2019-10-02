function [results,calibPassed , delayRegs] = calibrateDelays(hw, runParams, calibParams, results, fw, fnCalib, fprintff, thermalLoopEn)
    calibPassed = 1;
    fprintff('[-] Depth and IR delay calibration...\n');
    if(runParams.dataDelay)
        isFinalStage = isfield(results, 'conLocDelaySlow'); % calibrateDelays was called once before
        hw.setAlgoLoops(false, thermalLoopEn); % disabling sync loop
        Calibration.dataDelay.setAbsDelay(hw,calibParams.dataDelay.fastDelayInitVal,calibParams.dataDelay.slowDelayInitVal);
        Calibration.aux.CBTools.showImageRequestDialog(hw,1,diag([.6 .6 1]),'Delay Calibration',1);
        Calibration.aux.collectTempData(hw,runParams,fprintff,'Before delays calibration:');
        [delayRegs,delayCalibResults]=Calibration.dataDelay.calibrate(hw, calibParams.dataDelay, fprintff, runParams, calibParams, isFinalStage);
        
        % Sync Loop management
        curLddTemp = hw.getLddTemperature;
        if ~isFinalStage % initialization stage
            delayRegs.FRMW.conLocDelaySlowSlope = calibParams.dataDelay.slowDelayInitSlope;
            delayRegs.FRMW.conLocDelayFastSlope = calibParams.dataDelay.fastDelayInitSlope;
            delayRegs.FRMW.dfzCalTmp            = curLddTemp;
        else % finalization stage
            tempDiff                            = curLddTemp - results.dfzCalTmp;
            delayRegs.FRMW.conLocDelaySlowSlope = (delayCalibResults.delayIR - results.delayIR)/tempDiff;
            delayRegs.FRMW.conLocDelayFastSlope = (delayCalibResults.delayZ - results.delayZ)/tempDiff;
            delayRegs.FRMW.dfzCalTmp            = curLddTemp;
        end
        writeDelayRegsToDRAM(hw, delayRegs)
        pause(1)
        hw.setAlgoLoops(true, thermalLoopEn); % enabling sync loop

        fw.setRegs(delayRegs,fnCalib);
        
        results.delayIR                 = delayCalibResults.delayIR;
        results.delayZ                  = delayCalibResults.delayZ;
        results.conLocDelaySlow         = delayRegs.EXTL.conLocDelaySlow;
        results.conLocDelayFastC        = delayRegs.EXTL.conLocDelayFastC;
        results.conLocDelayFastF        = delayRegs.EXTL.conLocDelayFastF;
        results.conLocDelayFastSlope    = delayRegs.FRMW.conLocDelayFastSlope;
        results.conLocDelaySlowSlope    = delayRegs.FRMW.conLocDelaySlowSlope;
        results.dfzCalTmp               = delayRegs.FRMW.dfzCalTmp;
        results.delayS                  = (1- delayCalibResults.slowDelayCalibSuccess);
        results.delaySlowPixelVar       = delayCalibResults.delaySlowPixelVar;
        results.delayF                  = (1-delayCalibResults.fastDelayCalibSuccess);
        
        if delayCalibResults.slowDelayCalibSuccess 
            fprintff('[v] ir delay calib passed [e=%g]\n',results.delayS);
        else
            fprintff('[x] ir delay calib failed [e=%g]\n',results.delayS);
            calibPassed = 0;
        end
        
        pixVarRange = calibParams.errRange.delaySlowPixelVar;
        if  results.delaySlowPixelVar >= pixVarRange(1) &&...
                results.delaySlowPixelVar <= pixVarRange(2)
            fprintff('[v] ir vertical pixel alignment variance [e=%g]\n',results.delaySlowPixelVar);
        else
            fprintff('[x] ir vertical pixel alignment variance [e=%g]\n',results.delaySlowPixelVar);
            calibPassed = 0;
        end
        
        if delayCalibResults.fastDelayCalibSuccess
            fprintff('[v] depth delay calib passed [e=%g]\n',results.delayF);
        else
            fprintff('[x] depth delay calib failed [e=%g]\n',results.delayF);
            calibPassed = 0;
        end
        
    else
        delayRegs = struct;
        fprintff('skipped\n');
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function writeDelayRegsToDRAM(hw, delayRegs)

delayFastC = dec2hex(delayRegs.EXTL.conLocDelayFastC);
delayFastF = dec2hex(delayRegs.EXTL.conLocDelayFastF);
delaySlow = dec2hex(delayRegs.EXTL.conLocDelaySlow);
delayFastSlope = cell2mat(single2hex(delayRegs.FRMW.conLocDelayFastSlope));
delaySlowSlope = cell2mat(single2hex(delayRegs.FRMW.conLocDelaySlowSlope));
delayRefTmp = cell2mat(single2hex(delayRegs.FRMW.dfzCalTmp));
hw.cmd(sprintf('SET_PARAM_SYNC_LOOP 1 %s', delayFastC));
hw.cmd(sprintf('SET_PARAM_SYNC_LOOP 2 %s', delayFastF));
hw.cmd(sprintf('SET_PARAM_SYNC_LOOP 3 %s', delaySlow));
hw.cmd(sprintf('SET_PARAM_SYNC_LOOP 4 %s', delayFastSlope));
hw.cmd(sprintf('SET_PARAM_SYNC_LOOP 5 %s', delaySlowSlope));
hw.cmd(sprintf('SET_PARAM_SYNC_LOOP 6 %s', delayRefTmp));

end