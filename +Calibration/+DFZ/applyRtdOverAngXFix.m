function [ rtd2add ] = applyRtdOverAngXFix( angX,regs )
angX = (angX - regs.FRMW.rtdOverX(6))/2047;
rtd2add = regs.FRMW.rtdOverX(1)*angX.^2 + ...
                regs.FRMW.rtdOverX(2)*abs(angX).^3 + ...
                regs.FRMW.rtdOverX(3)*angX.^4 + ...
                regs.FRMW.rtdOverX(4)*abs(angX).^5 + ...
                regs.FRMW.rtdOverX(5)*angX.^6;


end
