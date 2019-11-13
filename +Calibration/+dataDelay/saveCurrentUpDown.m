function [  ] = saveCurrentUpDown( hw,runParams,block,name,titlestr )
[imU,imD]=Calibration.dataDelay.getScanDirImagesByLocTable(hw);
im=cat(3,imD,(imD+imU)/2,imU);
ff = Calibration.aux.invisibleFigure;
imagesc(im); title(titlestr);
Calibration.aux.saveFigureAsImage(ff,runParams,block,name);

end

