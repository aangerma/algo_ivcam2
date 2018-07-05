function setCode( hw,scpath)

hw.runPresetScript('maReset');
pause(0.1);
hw.runScript(scpath);
pause(0.1);
hw.runPresetScript('maRestart');
pause(0.1);
hw.cmd('mwd a00d01ec a00d01f0 00000001 // EXTLauxShadowUpdateFrame');
pause(0.1);

end

