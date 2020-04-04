close all
clear all
clc

%%

imagesPath = '\\percdsk350\AnalyzeResults\ResultsByTesterName\TESTER-GEN08\F0070050\ATC1\Images\Thermal\';

folders = dir([imagesPath, 'Cycle*']);
text2disp = '';
for k = 0:length(folders)-1
    fprintf(repmat(sprintf('\b'), 1, length(text2disp)));
    text2disp = sprintf('Reading cycle %d (%d%%)', k-1, round(100*k/length(folders)));
    fprintf(text2disp);
    fid = fopen([imagesPath, sprintf('Cycle%d\\I_480x1024_Cycle%d_9.bin', k, k)], 'rb');
    ir(:,:,k+1) = reshape(fread(fid, inf, '*uint8'), 480, 1024);
    fclose(fid);
    fid = fopen([imagesPath, sprintf('Cycle%d\\Z_480x1024_Cycle%d_9.bin', k, k)], 'rb');
    z(:,:,k+1) = reshape(typecast(fread(fid, inf, '*uint8'), 'uint16'), 480, 1024);
    fclose(fid);
end
fprintf('...Done!\n');

%%

hFig = figure;
set(hFig, 'Position', [680   558   850   420]);
hTitle = sgtitle('');
takePosVals = @(x) x(x>0);
for k = 1:length(folders)
    subplot(121)
    imagesc(ir(:,:,k))
    subplot(122)
    imagesc(z(:,:,k))
    set(gca, 'clim', prctile(takePosVals(z(:,:,k)), [5,80]))
    set(hTitle, 'String', sprintf('Cycle %d', k-1))
    shg
    pause(0.1)
end

