function [ postUndistAngx ] = applyPolyUndist( angx,regs )
%INVERSEPOLYUNDIST Inverting the polynomial 3rd degree fix to angx

postUndistAngx = angx + (angx/2047).^[1 2 3]*(regs.FRMW.polyVars');

end

