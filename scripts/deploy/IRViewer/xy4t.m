function xy = xy4t(t,fd)
xy = interp1(1:size(fd.tbl,1),fd.tbl,interp1(fd.mrt,1:length(fd.mrt),t-fd.t0,'linear','extrap')+fd.pixPhaseDelay);
end