function regsOut = genPSNRregs()
g = 1e-3;
miIRvalue = 1000;


regsOut.DCOR.irStartLUT = uint16(miIRvalue);
regsOut.DCOR.ambStartLUT = uint16(miIRvalue);
% 
% s = 0:0.1:10;
% phi = @(x) cdf('Normal',x,0,1);
% %folded gaussian distribution expectnecy
% efgd = @(u,s) s*sqrt(2/pi)*exp(-0.5*(u/s)^2)+u*(1-2*phi(-u/s));
% m1=efgd(-0.5*g*a,s)+efgd(+0.5*g*a,sqrt(s*s+g*g*a));
end