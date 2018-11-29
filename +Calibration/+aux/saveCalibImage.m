function [  ] = saveCalibImage( image,imtype,runParams,blockname,imname)
%SAVECALIBIMAGE saves an image to the output dir of the calibration under blockname/imname
if strcmp(imtype,'z') || strcmp(imtype,'Z')
    if max(vec(image)) > 0
        image = uint8(double(image)/double(max(vec(image)))*255);
    end
elseif strcmp(imtype,'c') || strcmp(imtype,'C')
    image = uint8(image*16);
elseif strcmp(imtype,'i') || strcmp(imtype,'I')
    if ~strcmp(class(image),'uint8') && max(vec(image)) > 0
        image = uint8(double(image)/double(max(vec(image)))*255);
    end
end
image = uint8(image);
imDir = fullfile(runParams.outputDir,'figures');
mkdirSafe(imDir);
impath = fullfile(imDir,strcat(blockname,'_',imname,'.png'));
imwrite(image,impath);


end
