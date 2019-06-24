function [ postUndistAngx,postUndistAngy ] = applyPolyUndistAndPitchFix1( angx,angy,regs )
    angxVec = angx(:);
    angyVec = angy(:);
    
    postUndistAngy = angyVec + angxVec/2047*regs.FRMW.pitchFixFactor;
    postUndistAngy = reshape(postUndistAngy,size(angy));
    %postUndistAngx = angxVec + (angxVec/2047).^(1:length(regs.FRMW.polyVars))*(vec(regs.FRMW.polyVars));
    if all(regs.FRMW.distortionCoeffs == 0)
        postUndistAngx = angx;
    else
        postUndistAngx = undistRbf(angxVec/2047,regs.FRMW.distortionCoeffs(1:79))*2047;
        postUndistAngx = reshape(postUndistAngx,size(angx));
        postUndistAngy = undistRbf(postUndistAngy(:)/2047,regs.FRMW.distortionCoeffs(80:end))*2047;
        postUndistAngy = reshape(postUndistAngy,size(angx));
    end
end


function ux = undistRbf(u,undistVars)
    Nc = length(undistVars)/2;
    centers = [-1+1/Nc:1/Nc:1-1/Nc];
    sigmas  = ones(size(centers))/Nc';
    E = [exp(-0.5*bsxfun(@rdivide, bsxfun(@minus, u, centers).^2, sigmas.^2))];
    ux = u + E*undistVars(1:size(E,2))';
end