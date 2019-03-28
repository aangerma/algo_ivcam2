function [mclog] = readPZRs(filename)

T = readtable(filename);
PZR = table2array(T);
PZR = PZR(1:end-1,:);

mclog.PZR1 = PZR(:,9);
mclog.PZR2 = PZR(:,11);
mclog.PZR3 = PZR(:,10);

mclog.angX = PZR(:,4);
mclog.angY = PZR(:,12);

mclog.t = PZR(:,13);

end


