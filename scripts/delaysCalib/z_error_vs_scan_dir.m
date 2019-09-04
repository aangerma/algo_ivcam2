clear variables
clc

%% Unit handling

% stream initiation
vgaRes = [480,640];
hw = HWinterface();
hw.cmd('dirtybitbypass');
hw.startStream(0,vgaRes)
hw.cmd('mwd a00e18b8 a00e18bc ffff0000');

% Capturing
nFrames = 30;
%hw.write('sphericalEn',uint32(1)), hw.write('sphericalScale',typecast(uint16(flip(vgaRes)),'uint32')), hw.shadowUpdate();
hw.write('sphericalEn',uint32(0)); hw.shadowUpdate();
gainCalibValue  = '000ffff0';
[val1, val2] = Calibration.aux.GetGainValue(hw);        % save original gain value
Calibration.aux.SetGainValue(hw,gainCalibValue, val2);  % Scan Direction up
imUp = hw.getFrame(nFrames);
Calibration.aux.SetGainValue(hw,val1, gainCalibValue);  % Scan Direction down
imDown = hw.getFrame(nFrames);
Calibration.aux.SetGainValue(hw,val1, val2);            % resore gain inital values
hw.stopStream

%% CB detection
ptsUp = Calibration.aux.CBTools.findCheckerboardFullMatrix(imUp.i,1,[],[],true);
ptsDown = Calibration.aux.CBTools.findCheckerboardFullMatrix(imDown.i,1,[],[],true);
isNanVal = isnan(ptsUp) | isnan(ptsDown);
ptsUp(isNanVal) = nan;
ptsDown(isNanVal) = nan;

% removal of excessive rows and columns
validRows = find(any(~isNanVal(:,:,1),2));
validCols = find(any(~isNanVal(:,:,1),1));
ptsUp = ptsUp(validRows, validCols, :);
ptsDown = ptsDown(validRows, validCols, :);
isNanVal = isNanVal(validRows, validCols, :);

%% CB visualization
figure('Position', [360, 198, 1366, 420])

subplot(121)
imagesc(imUp.i)
colormap gray
hold on
plot(vec(ptsUp(:,:,1)), vec(ptsUp(:,:,2)), 'r+')
title('Up')

subplot(122)
imagesc(imDown.i)
colormap gray
hold on
plot(vec(ptsDown(:,:,1)), vec(ptsDown(:,:,2)), 'r+')
title('Down')

%% Depth estimation
ptsUp(:,:,3) = nan;
ptsDown(:,:,3) = nan;
for iRow = 1:size(ptsUp,1)
    for iCol = 1:size(ptsUp,2)
        if ~isNanVal(iRow, iCol, 1)
            ptsUp(iRow, iCol, 3) = imUp.z(ceil(ptsUp(iRow, iCol, 2)), ceil(ptsUp(iRow, iCol, 1)));
            ptsDown(iRow, iCol, 3) = imDown.z(ceil(ptsDown(iRow, iCol, 2)), ceil(ptsDown(iRow, iCol, 1)));
        end
    end
end
upMinusDown = ptsUp(:,:,3)-ptsDown(:,:,3);
upMinusDownAv = mean(upMinusDown(~isnan(upMinusDown)));
upMinusDownRms = rms(upMinusDown(~isnan(upMinusDown)));

%% Depth visualization

% Depth
minmin = min([min(vec(ptsUp(:,:,3))), min(vec(ptsDown(:,:,3)))]);
maxmax = max([max(vec(ptsUp(:,:,3))), max(vec(ptsDown(:,:,3)))]);
zScale = 4;
clim = [minmin,maxmax]/zScale;
figure('Position', [360, 198, 1366, 420])

subplot(121)
h = imagesc(ptsUp(:,:,3)/zScale);
set(h, 'AlphaData', ~isnan(ptsUp(:,:,3)))
set(gca, 'clim', clim)
colorbar
title('Up')

subplot(122)
h = imagesc(ptsDown(:,:,3)/zScale);
set(h, 'AlphaData', ~isnan(ptsDown(:,:,3)))
set(gca, 'clim', clim)
colorbar
title('Down')

% Depth differences
minmin = min(vec(upMinusDown(:,:)));
maxmax = max(vec(upMinusDown(:,:)));
climDif = [minmin,maxmax]/zScale;
figure('Position', [360, 198, 1366, 420])

h = imagesc(upMinusDown/zScale);
set(h, 'AlphaData', ~isnan(upMinusDown))
set(gca, 'clim', climDif)
colorbar
title(sprintf('Up - Down\nmean = %.1f[mm], RMS = %.1f[mm]', upMinusDownAv/zScale, upMinusDownRms/zScale))

