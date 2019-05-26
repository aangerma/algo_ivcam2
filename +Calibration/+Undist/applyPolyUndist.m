function [ postUndistAngx ] = applyPolyUndist( angx,regs )
%INVERSEPOLYUNDIST Inverting the polynomial 3rd degree fix to angx
angxVec = angx(:);
postUndistAngx = angxVec + (angxVec/2047).^[1 2 3]*(regs.FRMW.polyVars(:));
postUndistAngx = reshape(postUndistAngx,size(angx));
end

