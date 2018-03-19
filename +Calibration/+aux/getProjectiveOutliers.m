function [inliers] = getProjectiveOutliers(regs,angles)
%GETPROJECTIVEOUTLIERS get the angles for the checkerboard points, try to
%fit a projective transformation to them and returns the inliers map.
[xx,yy] = Pipe.DIGG.ang2xy(int16(angles(:,:,1)),int16(angles(:,:,2)),regs,[],[]);
xx = double(xx)/2^double(regs.DIGG.bitshift);
yy = double(yy)/2^double(regs.DIGG.bitshift);

[~,~,~,inliers] = Calibration.aux.evalProjectiveDisotrtion([xx(:),yy(:)],size(xx));

end

