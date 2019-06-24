function [ postUndistAngx,postUndistAngy ] = applyPolyUndistAndPitchFix2( angx,angy,regs )
    angxVec = angx(:);
    angyVec = angy(:);
    
    
    [postUndistAngx, postUndistAngy] = undistRbf(angxVec/2047,angyVec/2047,regs.FRMW.polyVars);
    postUndistAngx = reshape(postUndistAngx,size(angx))*2047;
    postUndistAngy = reshape(postUndistAngy,size(angx))*2047;
    
end


function [ux,uy] = undistRbf(u,v,undistVars)
    Nx = 20;
    Ny = 20;
    cx = [-1+1/Nx:1/Nx:1-1/Nx];
    cy = [-1+1/Ny:1/Ny:1-1/Ny];
    sigmax  = ones(1,size(cx,1))/(Nx);
    sigmay  = ones(1,size(cy,1))/(Ny);
    Ex = exp(-0.5*bsxfun(@rdivide, bsxfun(@minus, u, cx).^2, sigmax.^2));
    Ey = exp(-0.5*bsxfun(@rdivide, bsxfun(@minus, v, cy).^2, sigmay.^2));
    ux = u + Ex*undistVars(1:(Nx*2-1))';
    uy = v + Ey*undistVars((Nx*2-1)+1:(Nx*2-1)+(Ny*2-1))';
end