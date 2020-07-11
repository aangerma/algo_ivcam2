function saveKtoDsmData(outputBinFilesPath, KtoDsmData)
%SAVECYCLEDATA Summary of this function goes here
%   Detailed explanation goes here 
    
  
    KtoDsmData.inputs.dsmRegs;
    
    newKdepth = KtoDsmData.inputs.newKdepth';
    f_name = sprintf('k2dsm_inpus_newKdepth_%d',KtoDsmData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, newKdepth(:)','double');
    
    oldKdepth = KtoDsmData.inputs.oldKdepth';
    f_name = sprintf('k2dsm_inpus_oldKdepth_%d',KtoDsmData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, oldKdepth(:)','double');
    
    f_name = sprintf('k2dsm_inpus_vertices_%d',KtoDsmData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, KtoDsmData.inputs.vertices,'double');
    
    acDataCand_vec = [KtoDsmData.inputs.acData.hFactor KtoDsmData.inputs.acData.vFactor];
    f_name = sprintf('k2dsm_inpus_acData_%d',KtoDsmData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, acDataCand_vec,'double');

    dsmRegsCandVec = [KtoDsmData.inputs.dsmRegs.dsmXscale ...
        KtoDsmData.inputs.dsmRegs.dsmYscale ...
        KtoDsmData.inputs.dsmRegs.dsmXoffset ...
        KtoDsmData.inputs.dsmRegs.dsmYoffset];
    
    f_name = sprintf('k2dsm_inpus_dsmRegs_%d',KtoDsmData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, dsmRegsCandVec,'double');
    
    dsmRegsOrigVec = [KtoDsmData.dsmRegsOrig.dsmXscale ...
        KtoDsmData.dsmRegsOrig.dsmYscale ...
        KtoDsmData.dsmRegsOrig.dsmXoffset ...
        KtoDsmData.dsmRegsOrig.dsmYoffset];
    
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath,sprintf('dsmRegsOrig_%d',KtoDsmData.cycle),dsmRegsOrigVec,'double');
          
     OnlineCalibration.aux.saveBinImage(outputBinFilesPath,sprintf('relevantPixelnImage_rot_%d',KtoDsmData.cycle), KtoDsmData.preProcData.relevantPixelnImage_rot,'uint8');
     lastLosVec = [ KtoDsmData.preProcData.lastLosScaling(:)',  KtoDsmData.preProcData.lastLosShift(:)'];

     OnlineCalibration.aux.saveBinImage(outputBinFilesPath, sprintf('dsm_los_error_orig_%d',KtoDsmData.cycle), lastLosVec', 'double');
     OnlineCalibration.aux.saveBinImage(outputBinFilesPath, sprintf('verticesOrig_%d',KtoDsmData.cycle), KtoDsmData.preProcData.verticesOrig,'double');
       
     
     save_ConvertNormVerticesToLos_data(outputBinFilesPath, 'first', KtoDsmData.cycle, KtoDsmData.first_ConvertNormVerticesToLos_data)
     OnlineCalibration.aux.saveBinImage(outputBinFilesPath, sprintf('losOrig_%d',KtoDsmData.cycle), KtoDsmData.preProcData.losOrig,'double');
  
    f_name = sprintf('errL2_%d',KtoDsmData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, KtoDsmData.errL2,'double');
    
    f_name = sprintf('sgMat_%d',KtoDsmData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, KtoDsmData.sgMat,'double');
       
    f_name = sprintf('sg_mat_tag_x_sg_mat_%d',KtoDsmData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, KtoDsmData.sg_mat_tag_x_sg_mat(:),'double');
   
    f_name = sprintf('sg_mat_tag_x_err_l2_%d',KtoDsmData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, KtoDsmData.sg_mat_tag_x_err_l2,'double');
   
    f_name = sprintf('quadCoef_%d',KtoDsmData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, KtoDsmData.quadCoef,'double');
    
    f_name = sprintf('focalScaling_%d',KtoDsmData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, KtoDsmData.focalScaling,'double');
    
    f_name = sprintf('optScaling1_%d',KtoDsmData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, KtoDsmData.optScaling1,'double');

    
    f_name = sprintf('optScaling_%d',KtoDsmData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, KtoDsmData.optScaling,'double');

    f_name = sprintf('newlosScaling_%d',KtoDsmData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, KtoDsmData.newlosScaling,'double');

    acDataCand_vec = [KtoDsmData.acDataCand.hFactor KtoDsmData.acDataCand.vFactor];
    f_name = sprintf('acDataCand_%d',KtoDsmData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, acDataCand_vec,'double');

    dsmRegsCandVec = [KtoDsmData.dsmRegsCand.dsmXscale ...
        KtoDsmData.dsmRegsCand.dsmYscale ...
        KtoDsmData.dsmRegsCand.dsmXoffset ...
        KtoDsmData.dsmRegsCand.dsmYoffset];
    
    f_name = sprintf('dsmRegsCand_%d',KtoDsmData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, dsmRegsCandVec,'double');

    save_ConvertNormVerticesToLos_data(outputBinFilesPath, 'second', KtoDsmData.cycle, KtoDsmData.second_ConvertNormVerticesToLos_data)
    
    f_name = sprintf('orig_los_%d',KtoDsmData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, KtoDsmData.orig_los,'double');
    
    f_name = sprintf('dsm_%d',KtoDsmData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, KtoDsmData.dsm,'double');
    
    f_name = sprintf('new_vertices_%d',KtoDsmData.cycle);  
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, KtoDsmData.vertices,'double');
    
end

function save_ConvertNormVerticesToLos_data(outputBinFilesPath, iter, cycle, data)
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, sprintf('%s_laserIncidentDirection_%d',iter, cycle), data.laserIncidentDirection,'double');
    
     OnlineCalibration.aux.saveBinImage(outputBinFilesPath, sprintf('%s_fovexIndicentDirection_%d',iter,cycle), data.fovexIndicentDirection,'double');
    
     OnlineCalibration.aux.saveBinImage(outputBinFilesPath, sprintf('%s_mirrorNormalDirection_%d',iter,cycle), data.mirrorNormalDirection,'double');
      
     OnlineCalibration.aux.saveBinImage(outputBinFilesPath, sprintf('%s_angX_%d',iter,cycle), data.angX,'double');
     OnlineCalibration.aux.saveBinImage(outputBinFilesPath, sprintf('%s_angY_%d',iter,cycle), data.angY,'double');  
     
     OnlineCalibration.aux.saveBinImage(outputBinFilesPath, sprintf('%s_dsmXcorr_%d',iter,cycle), data.dsmXcorr,'double');
     OnlineCalibration.aux.saveBinImage(outputBinFilesPath, sprintf('%s_dsmYcorr_%d',iter,cycle), data.dsmYcorr,'double');
  
     OnlineCalibration.aux.saveBinImage(outputBinFilesPath, sprintf('%s_dsmXcorr_%d',iter,cycle), data.dsmXcorr,'double');
     OnlineCalibration.aux.saveBinImage(outputBinFilesPath, sprintf('%s_dsmYcorr_%d',iter,cycle), data.dsmYcorr,'double');
  
     OnlineCalibration.aux.saveBinImage(outputBinFilesPath, sprintf('%s_dsmX_%d',iter,cycle), data.dsmX,'double');
     OnlineCalibration.aux.saveBinImage(outputBinFilesPath, sprintf('%s_dsmY_%d',iter,cycle), data.dsmY,'double');
  
end