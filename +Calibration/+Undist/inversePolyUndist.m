function [ preUndistRegs ] = inversePolyUndist( angx,regs )
%INVERSEPOLYUNDIST Inverting the polynomial 3rd degree fix to angx

x = (-2500:2500)';
y = Calibration.Undist.applyPolyUndist(x,regs);
preUndistRegs = interp1(y,x,angx);

end

