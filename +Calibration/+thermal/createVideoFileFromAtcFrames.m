function createVideoFileFromAtcFrames(imagesPath, aviName, aviRate)

figure(1)
cycles = dir([imagesPath, 'Cycle*']);
text2disp = '';
for iCycle = 1:length(cycles)
    fprintf(repmat(sprintf('\b'),[1,length(text2disp)]));
    text2disp = sprintf('processing... (%d%%)', round(100*iCycle/length(cycles)));
    fprintf('%s',text2disp)
    % read frame
    fn = sprintf('%sCycle%d\\I_480x1024_Cycle%d_9.bin', imagesPath, iCycle-1, iCycle-1);
    IR = io.readGeneralBin(fn, 'uint8', [1024,480])';
    % plot
    if (iCycle==1)
        h = imagesc(IR);
        colormap gray
    else
        set(h, 'CData', IR)
    end
    title(sprintf('Cycle %d', iCycle-1))
    F(iCycle) = getframe(gcf);
    pause(0.1)
end
% video generation
writerObj = VideoWriter(aviName);
writerObj.FrameRate = aviRate;
open(writerObj)
for iCycle = 1:length(cycles)
    writeVideo(writerObj, F(iCycle));
end
close(writerObj)
close(1)
fprintf('\nDone!\n');
