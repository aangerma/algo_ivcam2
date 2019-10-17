clear variables
clc

%% Unit handling

% stream initiation
vgaRes = [480,640];
hw = HWinterface();
hw.cmd('dirtybitbypass');
hw.startStream(0,vgaRes)
hw.cmd('mwd a00e18b8 a00e18bc ffff0000'); % JFIL invalidate min max
hw.cmd('mwd a00e0894 a00e0898 00000001'); % depth as range

upDown = 'both'; % 'up', 'down', 'both'
if ~strcmp(upDown,'both')
    gainCalibValue  = '000ffff0';
    [val1, val2] = Calibration.aux.GetGainValue(hw);        % save original gain value
    if strcmp(upDown, 'up')
        Calibration.aux.SetGainValue(hw,gainCalibValue, val2);  % Scan Direction up
    elseif strcmp(upDown, 'down')
        Calibration.aux.SetGainValue(hw,val1, gainCalibValue);  % Scan Direction down
    else
        error('unknown image type')
    end
end

% Capturing
nFrames = 30;
sphericalFactor = [1.25, 1.06];
hw.write('sphericalEn',uint32(1)); hw.write('sphericalScale',typecast(uint16(flip(vgaRes.*sphericalFactor)),'uint32')); hw.shadowUpdate();
imSphMag = hw.getFrame(nFrames);
pause(2);
hw.write('sphericalEn',uint32(1)), hw.write('sphericalScale',typecast(uint16(flip(vgaRes)),'uint32')), hw.shadowUpdate();
imSphFull = hw.getFrame(nFrames);
pause(2);
hw.write('sphericalEn',uint32(0)); hw.shadowUpdate();
imNonSph = hw.getFrame(nFrames);
if ~strcmp(upDown,'both')
    Calibration.aux.SetGainValue(hw,val1, val2);            % resore gain inital values
end
hw.stopStream

%% CB detection
ptsSphMag = CBTools.findCheckerboardFullMatrix(imSphMag.i,1,[],[],true);
ptsSphFull = CBTools.findCheckerboardFullMatrix(imSphFull.i,1,[],[],true);
ptsNonSph = CBTools.findCheckerboardFullMatrix(imNonSph.i,1,[],[],true);
isNanVal = isnan(ptsSphMag) | isnan(ptsSphFull) | isnan(ptsNonSph);
ptsSphMag(isNanVal) = nan;
ptsSphFull(isNanVal) = nan;
ptsNonSph(isNanVal) = nan;

% removal of excessive rows and columns
validRows = find(any(~isNanVal(:,:,1),2));
validCols = find(any(~isNanVal(:,:,1),1));
ptsSphMag = ptsSphMag(validRows, validCols, :);
ptsSphFull = ptsSphFull(validRows, validCols, :);
ptsNonSph = ptsNonSph(validRows, validCols, :);
isNanVal = isNanVal(validRows, validCols, :);

%% CB visualization
figure('Position', [360, 198, 1366, 420])

subplot(131)
imagesc(imSphMag.i)
colormap gray
hold on
plot(vec(ptsSphMag(:,:,1)), vec(ptsSphMag(:,:,2)), 'r+')
title('spherical magnified')

subplot(132)
imagesc(imSphFull.i)
colormap gray
hold on
plot(vec(ptsSphFull(:,:,1)), vec(ptsSphFull(:,:,2)), 'r+')
title('spherical full')

subplot(133)
imagesc(imNonSph.i)
colormap gray
hold on
plot(vec(ptsNonSph(:,:,1)), vec(ptsNonSph(:,:,2)), 'r+')
title('image plane')

%% Depth estimation
ptsSphMag(:,:,3) = nan;
ptsSphFull(:,:,3) = nan;
ptsNonSph(:,:,3) = nan;
for iRow = 1:size(ptsSphMag,1)
    for iCol = 1:size(ptsSphMag,2)
        if ~isNanVal(iRow, iCol, 1)
            ptsSphMag(iRow, iCol, 3) = imSphMag.z(ceil(ptsSphMag(iRow, iCol, 2)), ceil(ptsSphMag(iRow, iCol, 1)));
            ptsSphFull(iRow, iCol, 3) = imSphFull.z(ceil(ptsSphFull(iRow, iCol, 2)), ceil(ptsSphFull(iRow, iCol, 1)));
            ptsNonSph(iRow, iCol, 3) = imNonSph.z(ceil(ptsNonSph(iRow, iCol, 2)), ceil(ptsNonSph(iRow, iCol, 1)));
        end
    end
end
fullMinusMag = ptsSphFull(:,:,3)-ptsSphMag(:,:,3);
fullMinusNon = ptsSphFull(:,:,3)-ptsNonSph(:,:,3);
nonMinusMag = ptsNonSph(:,:,3)-ptsSphMag(:,:,3);
fullMinusMagAv = mean(fullMinusMag(~isnan(fullMinusMag)));
fullMinusNonAv = mean(fullMinusNon(~isnan(fullMinusNon)));
nonMinusMagAv = mean(nonMinusMag(~isnan(nonMinusMag)));
fullMinusMagRms = rms(fullMinusMag(~isnan(fullMinusMag)));
fullMinusNonRms = rms(fullMinusNon(~isnan(fullMinusNon)));
nonMinusMagRms = rms(nonMinusMag(~isnan(nonMinusMag)));

%% Depth visualization

% Depth
minmin = min([min(vec(ptsSphMag(:,:,3))), min(vec(ptsSphFull(:,:,3))), min(vec(ptsNonSph(:,:,3)))]);
maxmax = max([max(vec(ptsSphMag(:,:,3))), max(vec(ptsSphFull(:,:,3))), max(vec(ptsNonSph(:,:,3)))]);
zScale = 4;
clim = [minmin,maxmax]/zScale;
figure('Position', [360, 198, 1366, 420])

subplot(131)
h = imagesc(ptsSphMag(:,:,3)/zScale);
set(h, 'AlphaData', ~isnan(ptsSphMag(:,:,3)))
set(gca, 'clim', clim)
colorbar
title('spherical magnified')

subplot(132)
h = imagesc(ptsSphFull(:,:,3)/zScale);
set(h, 'AlphaData', ~isnan(ptsSphFull(:,:,3)))
set(gca, 'clim', clim)
colorbar
title('spherical full')

subplot(133)
h = imagesc(ptsNonSph(:,:,3)/zScale);
set(h, 'AlphaData', ~isnan(ptsNonSph(:,:,3)))
set(gca, 'clim', clim)
colorbar
title('image plane')

% Depth differences
minmin = min([min(vec(fullMinusMag(:,:))), min(vec(fullMinusNon(:,:))), min(vec(nonMinusMag(:,:)))]);
maxmax = max([max(vec(fullMinusMag(:,:))), max(vec(fullMinusNon(:,:))), max(vec(nonMinusMag(:,:)))]);
climDif = [minmin,maxmax]/zScale;
figure('Position', [360, 198, 1366, 420])

subplot(131)
h = imagesc(fullMinusMag/zScale);
set(h, 'AlphaData', ~isnan(fullMinusMag))
set(gca, 'clim', climDif)
colorbar
title(sprintf('(spherical full) - (spherical magnified)\nmean = %.1f[mm], RMS = %.1f[mm]', fullMinusMagAv/zScale, fullMinusMagRms/zScale))

subplot(132)
h = imagesc(fullMinusNon/zScale);
set(h, 'AlphaData', ~isnan(fullMinusNon))
set(gca, 'clim', climDif)
colorbar
title(sprintf('(spherical full) - (image plane)\nmean = %.1f[mm], RMS = %.1f[mm]', fullMinusNonAv/zScale, fullMinusNonRms/zScale))

subplot(133)
h = imagesc(nonMinusMag/zScale);
set(h, 'AlphaData', ~isnan(nonMinusMag))
set(gca, 'clim', climDif)
colorbar
title(sprintf('(image plane) - (spherical magnified)\nmean = %.1f[mm], RMS = %.1f[mm]', nonMinusMagAv/zScale, nonMinusMagRms/zScale))
