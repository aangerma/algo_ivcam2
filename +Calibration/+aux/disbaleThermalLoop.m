function [  ] = disbaleThermalLoop( hw,calibParams,fprintff,actuallyEnable )
if calibParams.gnrl.disablePZRThermal
    if actuallyEnable
        hw.cmd('ThermalLoopIndexSet 1 17 1');
        hw.cmd('ThermalLoopIndexSet 2 17 1');
        hw.cmd('ThermalLoopIndexSet 3 17 1');
        
    else
        fprintff('Disabling PZR thermal...\n'); 
        hw.cmd('ThermalStop');
        hw.cmd('ThermalLoopIndexSet 1 17 0');
        hw.cmd('ThermalLoopIndexSet 2 17 0');
        hw.cmd('ThermalLoopIndexSet 3 17 0');

        hw.cmd(sprintf('mwd fffc6034 fffc6038 %d',calibParams.gnrl.iBias(1)));
        hw.cmd(sprintf('mwd fffc602c fffc6030 %d',calibParams.gnrl.iBias(2)));
        hw.cmd(sprintf('mwd fffc603c fffc6040 %d',calibParams.gnrl.iBias(3)));


    end
   
end
if (~actuallyEnable) && calibParams.gnrl.disablePitchMemsCalib
   fprintff('Disabling mems pitch calibration...\n');
   hw.cmd('mwd fffe82bc fffe82c0 0');
   hw.cmd('mwd fffe82c0 fffe82c4 0');
   
   hw.cmd('mwd fffe82c4 fffe82c8 0');
   hw.cmd('mwd fffe82c8 fffe82cc 0');
end

end

