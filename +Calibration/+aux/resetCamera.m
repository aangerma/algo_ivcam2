function [ hw ] = resetCamera( hw )
hw.stopStream;
hw.cmd('rst');
pause(10);
clear hw;
pause(1);
hw = HWinterface;
hw.cmd('DIRTYBITBYPASS');

end

