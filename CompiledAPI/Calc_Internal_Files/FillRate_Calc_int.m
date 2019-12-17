function results = FillRate_Calc_int(im, calibParams, runParams)
% Call the Validation function 
nFrames = size(im.z,3);
if ~isfield(im,'z')
    error('FillRate_Calc_int: No Z images in frame bytes!');
end
if ~isfield(im,'i')
    error('FillRate_Calc_int: No Z images in frame bytes!');
end
for i = 1:nFrames
    frames(i).z = im.z(:,:,i);
    frames(i).i = im.i(:,:,i);
end

params = calibParams.fillRate.params;
[score, results, dbg] = Validation.metrics.fillRate(frames,params);

mask = Validation.aux.getRoiCircle(size(frames(1).z), params);

ff = Calibration.aux.invisibleFigure;
subplot(2,1,1);imagesc(imfuse(frames(1).i,mask));title('IR image with ROI mask');
subplot(2,1,2);imagesc(imfuse(frames(1).z>0,mask));title(sprintf('Valid depth image with ROI mask FR = %3.2f',score));
Calibration.aux.saveFigureAsImage(ff,runParams,'FillRates','IR_And_Z_Masked',1,0);

end