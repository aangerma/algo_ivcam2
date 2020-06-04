function saveCycleData(outputBinFilesPath, CycleData)
%SAVECYCLEDATA Summary of this function goes here
%   Detailed explanation goes here 
    dsmRegsOrigVec = [CycleData.dsmRegsOrig.dsmXscale ...
        CycleData.dsmRegsOrig.dsmYscale ...
        CycleData.dsmRegsOrig.dsmXoffset ...
        CycleData.dsmRegsOrig.dsmYoffset];
    
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,sprintf('dsmRegsOrig_%d',CycleData.cycle),dsmRegsOrigVec,'double');
          
     OnlineCalibration.aux.saveBinImage(outputBinFilesPath,sprintf('relevantPixelnImage_rot_%d',CycleData.cycle), CycleData.preProcData.relevantPixelnImage_rot,'uint8');
     lastLosVec = [ CycleData.preProcData.lastLosScaling(:)',  CycleData.preProcData.lastLosShift(:)'];

     OnlineCalibration.aux.saveBinImage(outputBinFilesPath, sprintf('dsm_los_error_orig_%d',CycleData.cycle), lastLosVec', 'double');
     OnlineCalibration.aux.saveBinImage(outputBinFilesPath, sprintf('verticesOrig_%d',CycleData.cycle), CycleData.preProcData.verticesOrig,'double');
     OnlineCalibration.aux.saveBinImage(outputBinFilesPath, sprintf('losOrig_%d',CycleData.cycle), CycleData.preProcData.losOrig,'double');
  
    f_name = sprintf('errL2_%d',CycleData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, CycleData.errL2,'double');
    
    f_name = sprintf('sgMat_%d',CycleData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, CycleData.sgMat,'double');
       
    f_name = sprintf('sg_mat_tag_x_sg_mat_%d',CycleData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, CycleData.sg_mat_tag_x_sg_mat(:),'double');
   
    f_name = sprintf('sg_mat_tag_x_err_l2_%d',CycleData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, CycleData.sg_mat_tag_x_err_l2,'double');
   
    f_name = sprintf('quadCoef_%d',CycleData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, CycleData.quadCoef,'double');
    
    f_name = sprintf('focalScaling_%d',CycleData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, CycleData.focalScaling,'double');
    
    f_name = sprintf('optScaling_%d',CycleData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, CycleData.optScaling,'double');

    f_name = sprintf('newlosScaling_%d',CycleData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, CycleData.newlosScaling,'double');

    acDataCand_vec = [CycleData.acDataCand.hFactor CycleData.acDataCand.vFactor];
    f_name = sprintf('acDataCand_%d',CycleData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, acDataCand_vec,'double');

    dsmRegsCandVec = [CycleData.dsmRegsCand.dsmXscale ...
        CycleData.dsmRegsCand.dsmYscale ...
        CycleData.dsmRegsCand.dsmXoffset ...
        CycleData.dsmRegsCand.dsmYoffset];
    
    f_name = sprintf('dsmRegsCand_%d',CycleData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, dsmRegsCandVec,'double');

    f_name = sprintf('orig_los_%d',CycleData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, CycleData.orig_los,'double');
    
    f_name = sprintf('dsm_%d',CycleData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, CycleData.dsm,'double');
    
    f_name = sprintf('new_vertices_cycle_%d',CycleData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, CycleData.vertices,'double');
end

