function [delay] = computeDelay(mclog)

dsmLineX = polyfit(mclog.t, mclog.angX, 1);
actLineX = polyfit(mclog.t, mclog.actAngX, 1);

figure; plot(mclog.t, mclog.angX);
hold on; plot(mclog.t, mclog.actAngX);
hold on; plot(mclog.t, polyval(dsmLineX, mclog.t));
hold on; plot(mclog.t, polyval(actLineX, mclog.t));

delay = (dsmLineX(2) - actLineX(2)) / ((dsmLineX(1)+actLineX(1))/2);

%t = 1:mclog.t(end);

%Y = interp1(mclog.t, mclog.angY, t);

end

