function [ postUndistAngx, postUndistAngy ] = applyPolyUndistAndPitchFix( angx, angy, regs )
% Applies undistortion accounting for MC errors in reported angles.
%   Input & output angles are all in DSM units.

angxVec = angx(:);
angyVec = angy(:);
scaleFactor = 2047; % max value for 12-bit signed

% coarse (stage 1) undist
stage1UndistAngx = angxVec + (angxVec/scaleFactor).^[1,2,3]*(vec(regs.FRMW.polyVars));
stage1UndistAngy = angyVec + (angxVec/scaleFactor)*regs.FRMW.pitchFixFactor;
% fine (stage 2) undist
[postUndistAngx, postUndistAngy] = applyFineTuningUndist(stage1UndistAngx, stage1UndistAngy, regs);

postUndistAngx = reshape(postUndistAngx,size(angx));
postUndistAngy = reshape(postUndistAngy,size(angy));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ postUndistAngx, postUndistAngy ] = applyFineTuningUndist( angx, angy, regs)

assert(length(angx)==length(angy), 'applyFineTuningUndist: angx & angy must be of equal size')
scaleFactor = 2047; % max value for 12-bit signed

postUndistAngx = angx + (angx/scaleFactor).^[1,2,3,4]*vec(regs.FRMW.undistAngHorz);
postUndistAngy = angy + (angy/scaleFactor).^[1,2,3,4]*vec(regs.FRMW.undistAngVert);

end