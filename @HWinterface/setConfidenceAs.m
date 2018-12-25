function [  ] = setConfidenceAs(obj, input )
%SETCONFIDENCEAS sets the current confidence configuration to output 1 of
%the 4 inputs. Inputs should be one of ('maxPeak','IR','dc','psnr'). No
%input sets the confidence to the current confidence configuration.
% [maxPeak,IR,dc,psnr]
if exist('input','var')
    inputIdx = strcmpi(input,'ir')*4 + ...
               strcmpi(input,'dc')*1 + ...
               strcmpi(input,'psnr')*2 + ...
               strcmpi(input,'maxpeak')*3;
else
    inputIdx = 0;
end
filedir = fileparts(mfilename('fullpath'));
fwpath = fullfile(filedir,'../+Calibration/releaseConfigCalib');
fw = Pipe.loadFirmware(fwpath); 
if inputIdx > 0 % Set confidence configuration from 
    
    regs.DEST.confw1 = int8([0,0,0,0]);
    regs.DEST.confw1(inputIdx) = 1;
    regs.DEST.confv = int8([0,0,0,0]);
    regs.DEST.confactIn = int16([-128,255]);
    regs.DEST.confq = int8([4,0]);
    regs.DEST.confactOt = int16([0,255]);
    regs.DEST.confw2 = int8([0,0,0,0]);
    fw.setRegs(regs,'');
    fw.get();
end
scname = [tempname,'.txt'];
fw.genMWDcmd('DESTconf',scname);
obj.runScript(scname);
obj.shadowUpdate;
end


