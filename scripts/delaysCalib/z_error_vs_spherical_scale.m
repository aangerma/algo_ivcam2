clear variables
clc

%%

hw = HWinterface();
hw.cmd('dirtybitbypass');
hw.startStream(0,[480,640])

%% Capturing

hw.write('sphericalEn',uint32(1)); hw.write('sphericalScale',typecast(uint16([650,570]),'uint32')); hw.shadowUpdate();
imSphMag = hw.getFrame(30);
hw.write('sphericalEn',uint32(1)), hw.write('sphericalScale',typecast(uint16([640,480]),'uint32')), hw.shadowUpdate()
imSphFull = hw.getFrame(30);
hw.stopStream

%% CB detection

ptsSphMag = Calibration.aux.CBTools.findCheckerboardFullMatrix(imSphMag.i,1,[],[],true);
ptsSphFull = Calibration.aux.CBTools.findCheckerboardFullMatrix(imSphFull.i,1,[],[],true);
ptsSphMag(isnan(ptsSphFull)) = nan;
ptsSphFull(isnan(ptsSphMag)) = nan;

figure

subplot(121)
imagesc(imSphMag.i)
colormap gray
hold on
plot(vec(ptsSphMag(:,:,1)), vec(ptsSphMag(:,:,2)), 'r+')
title('spherical magnified')

subplot(122)
imagesc(imSphFull.i)
colormap gray
hold on
plot(vec(ptsSphFull(:,:,1)), vec(ptsSphFull(:,:,2)), 'r+')
title('spherical full')

%% Depth difference

ptsSphMag(:,:,3) = nan;
ptsSphFull(:,:,3) = nan;
for iRow = 1:size(ptsSphMag,1)
    for iCol = 1:size(ptsSphMag,2)
        if ~isnan(ptsSphMag(iRow, iCol, 1))
            ptsSphMag(iRow, iCol, 3) = imSphMag.z(ceil(ptsSphMag(iRow, iCol, 2)), ceil(ptsSphMag(iRow, iCol, 1)));
        end
        if ~isnan(ptsSphFull(iRow, iCol, 1))
            ptsSphFull(iRow, iCol, 3) = imSphFull.z(ceil(ptsSphFull(iRow, iCol, 2)), ceil(ptsSphFull(iRow, iCol, 1)));
        end
    end
end
fullMagDif = ptsSphFull(:,:,3)-ptsSphMag(:,:,3);

clim = [350,400];
figure

subplot(131)
imagesc(ptsSphMag(:,:,3)/4)
set(gca, 'clim', clim)
colorbar
title('spherical magnified')

subplot(132)
imagesc(ptsSphFull(:,:,3)/4)
set(gca, 'clim', clim)
colorbar
title('spherical full')

subplot(133)
imagesc(fullMagDif/4)
set(gca, 'clim', [0,20])
colorbar
title('full-magnitude')
