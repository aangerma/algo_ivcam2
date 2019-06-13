function [  ] = saveDFZInputImage( frames, runParams )
%SAVEDFZINPUTIMAGE saves a  figure of the IR with the detected checkerboard
%both for DFZ and for undist


for i = 1:numel(frames)
   
    ff = Calibration.aux.invisibleFigure; 
    imagesc(frames(i).i); colormap gray;    
    pCirc = Calibration.DFZ.getCBCircPoints(frames(i).pts,frames(i).grid);
    pCircCropped = Calibration.DFZ.getCBCircPoints(frames(i).ptsCropped,frames(i).gridCropped);
    hold on;
    plot(pCirc(:,1),pCirc(:,2),'r','linewidth',3)
    plot(vec(frames(i).pts(:,:,1)),vec(frames(i).pts(:,:,2)),'+r')

    plot(pCircCropped(:,1),pCircCropped(:,2),'g','linewidth',3)
    plot(vec(frames(i).ptsCropped(:,:,1)),vec(frames(i).ptsCropped(:,:,2)),'og')

    hold off
    title(sprintf('Full and Cropped CB: GridFull=[%d,%d], GridCropped=[%d,%d]',frames(i).grid(1),frames(i).grid(2),frames(i).gridCropped(1),frames(i).gridCropped(2)));
    Calibration.aux.saveFigureAsImage(ff,runParams,'DFZ','InputImage',1)
    
         
end

end

