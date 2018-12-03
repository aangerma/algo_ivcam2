fw = Pipe.loadFirmware('C:\temp\unitCalib\F8200076\PC09\AlgoInternal');
fw.get();

%% Collect 3 captures of the scene
hw = HWinterface;
% Same as today 

% No JFIL or RAST Filter 
r=Calibration.RegState(hw);
%% SET
r.add('RASTbiltBypass'     ,true     );
r.add('JFILbypass$'        ,true    );
r.set();
hw.cmd('mwd a0020a6c a0020a70 1000100 // DIGGgammaScale');

r.reset();
%% No JFIL or RAST with PURE RTD
r=Calibration.RegState(hw);
r.add('RASTbiltBypass'     ,true     );
r.add('JFILbypass$'        ,true    );
r.add('DESTbaseline$'        ,single(0)    );
r.add('DESTbaseline2'        ,single(0)    );
r.add('DESTdepthAsRange'        ,true    );

r.set();
hw.cmd('mwd a0020a6c a0020a70 1000100 // DIGGgammaScale');

r.reset();