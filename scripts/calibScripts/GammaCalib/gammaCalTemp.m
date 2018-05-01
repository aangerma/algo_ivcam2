fprintff = @fprintf;
fw = Firmware;
hw = HWinterface(fw);
params.verbose = true;

%% ::gamma::
params.gamma = true;
fprintff('gamma...\n');
if (params.gamma)
    
    [gammaregs,results.gammaErr] = Calibration.aux.runGammaCalib(hw,params.verbose);
    
    if(inrange(results.gammaErr,calibParams.errRange.gammaErr))
        fprintff('[v] gamma passed[e=%g]\n',results.gammaErr);
    else
        fprintff('[x] gamma failed[e=%g]\n',results.gammaErr);
        score = 0;
        return;
    end
    fw.setRegs(gammaregs,fnCalib);
else
    results.gammaErr=inf;
    fprintff('skipped\n');
end