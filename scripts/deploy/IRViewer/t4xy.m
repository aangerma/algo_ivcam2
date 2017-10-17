function t=t4xy(xy ,fd)
t= interp1(1:length(fd.mrt),fd.mrt,arrayfun(@(i) minind(sum(abs(bsxfun(@minus,fd.tbl,xy(i,:))),2)),1:size(xy,1))-fd.pixPhaseDelay,'linear','extrap')+fd.t0;
end