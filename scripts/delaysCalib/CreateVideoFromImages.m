function CreateVideoFromImages(imagesArr, func, clims, clrMap, figTitle, aviName, aviRate, temps)

figure(1)
nEpochs = size(imagesArr,3);
for k = 1:nEpochs
    if (k==1)
        h = imagesc(func(imagesArr(:,:,k)));
        set(gca,'xdir','reverse')
        set(gca,'ydir','normal')
        colormap(clrMap)
        colorbar
        if ~isempty(clims)
            set(gca,'clim',clims)
        end
    else
        set(h, 'CData', func(imagesArr(:,:,k)))
    end
    title(sprintf('%s (T = %.2f[deg])', figTitle, temps(k)))
    F(k) = getframe(gcf);
    pause(1)
end
writerObj = VideoWriter(aviName);
writerObj.FrameRate = aviRate;
open(writerObj)
for k = 1:nEpochs
    writeVideo(writerObj, F(k));
end
close(writerObj)
close(1)
