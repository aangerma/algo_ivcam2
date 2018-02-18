function [] = writeDODParamsMWD(filename, resDODParams)
if exist(filename, 'file') == 2
    fprintf('%s already exists. Overriding...',filename);
end

fw = Firmware;
fw.setRegs(resDODParams.regs,filename);
fw.setLut(resDODParams.luts);
[regs,luts] = fw.get();
fw.genMWDcmd([],filename);

% dodFW = fullfile(filename,'..','dodFW.mat');
% save(dodFW,'regs','luts')

end

