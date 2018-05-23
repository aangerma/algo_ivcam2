% hw.burn2device('c:\temp\TT\',1,1);


fw = Pipe.loadFirmware('\\tmund-MOBL1\C$\source\algo_ivcam2\+Calibration\initScript');
hw = HWinterface(fw);



%% Read all regs, compare to desired regs.
fw = Pipe.loadFirmware('c:\temp\TT\AlgoInternal');
[regs,luts] = fw.get();


m = fw.getMeta();
% Read all regs
hw = HWinterface(fw);
for i = 551:numel(m)
   devVal = hw.cmd(sprintf('mrd %08x %08x',m(i).address(1),m(i).address(1)+4) );
   devVal = lower(devVal(end-7:end));
   
   calibVal = fw.genMWDcmd([m(i).regName '$']);
   calibVal = lower(calibVal(23:30));
   if ~all(calibVal == devVal)
%       fprintf('Diff found between calib fw regs to device reg.\n ',m(i).regName) 
      fprintf('[%4d]: Reg name is %s. %s -> %s  (FW -> Device). \n',i,m(i).regName,calibVal,devVal) 
      
   end
   pause(0.1);
end