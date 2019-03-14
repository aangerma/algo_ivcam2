function [angX,angY] = calcAngleFromPZRs(mcLog,PZR_W)

A = PZR_W(1);
B = PZR_W(2);
C = PZR_W(3);
D = PZR_W(4);
E = PZR_W(5);

SA_RAW = A*mcLog.PZR1 + B*mcLog.PZR3;
PA_RAW = C*mcLog.PZR1 - D*mcLog.PZR3;
FA_RAW = E*mcLog.PZR2;

angX = SA_RAW;
angY = PA_RAW + FA_RAW;

end

