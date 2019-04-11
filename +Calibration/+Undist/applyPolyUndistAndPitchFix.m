function [ postUndistAngx,postUndistAngy ] = applyPolyUndistAndPitchFix( angx,angy,regs )
angxVec = angx(:);
angyVec = angy(:);

postUndistAngy = angyVec + angxVec/2047*regs.FRMW.pitchFixFactor;
postUndistAngy = reshape(postUndistAngy,size(angy));
postUndistAngx = angxVec + (angxVec/2047).^[1 2 3]*(regs.FRMW.polyVars');
postUndistAngx = reshape(postUndistAngx,size(angx));
end
