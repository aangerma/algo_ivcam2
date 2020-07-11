function saveCycleData(outputBinFilesPath, CycleData)

	p_matrix = CycleData.newParamsK2DSM.rgbPmat';
	f_name = sprintf('end_cycle_p_matrix_%d',CycleData.cycle);  
	OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, p_matrix(:)','double');
        
	f_name = sprintf('end_cycle_Kdepth_%d',CycleData.cycle);  
	OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, CycleData.newParamsK2DSM.Kdepth,'double');
    
    f_name = sprintf('end_cycle_Krgb_%d',CycleData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, CycleData.newParamsK2DSM.Krgb,'double');
    
    f_name = sprintf('converged_reasone_%d',CycleData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, CycleData.converged_resone,'uint8');
    
        acDataCand_vec = [CycleData.acData.hFactor CycleData.acData.vFactor];
        f_name = sprintf('end_cycle_acData_%d',CycleData.cycle);  
        OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, acDataCand_vec,'double');
        
        dsmRegsCandVec = [CycleData.dsmRegs.dsmXscale ...
        CycleData.dsmRegs.dsmYscale ...
        CycleData.dsmRegs.dsmXoffset ...
        CycleData.dsmRegs.dsmYoffset];
    
        f_name = sprintf('end_cycle_dsmRegsCand_%d',CycleData.cycle);  
        OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, dsmRegsCandVec,'double');

end