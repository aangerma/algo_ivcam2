function undistortedPixels = UndistortPixels(pixels, imageSize, K, dist)

paddingFactor = 0.2;
dilutionRatio = 4; % achieves ~1e-3 pixels accuracy with heavily reduced run-time
xGridVec = round(-paddingFactor*imageSize(2)):dilutionRatio:round(1+paddingFactor)*imageSize(2);
yGridVec = round(-paddingFactor*imageSize(1)):dilutionRatio:round(1+paddingFactor)*imageSize(1);
[yGridMat, xGridMat] = ndgrid(yGridVec, xGridVec);
pixelsGrid = [xGridMat(:), yGridMat(:)]';
pixelsGridDistorted = double(du.math.distortCam(pixelsGrid, K, dist));

pixels = double(pixels);
xUndistorted = griddata(pixelsGridDistorted(1,:)', pixelsGridDistorted(2,:)', xGridMat(:), pixels(1,:)'-1, pixels(2,:)'-1);
yUndistorted = griddata(pixelsGridDistorted(1,:)', pixelsGridDistorted(2,:)', yGridMat(:), pixels(1,:)'-1, pixels(2,:)'-1);
undistortedPixels = [xUndistorted, yUndistorted]'+1;

end