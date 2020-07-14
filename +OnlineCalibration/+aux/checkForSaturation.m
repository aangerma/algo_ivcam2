function [notSaturated,dbg] = checkForSaturation(im,saturationValue,saturationRatioTh,outputBinFilesPath)
% Checks that no more than saturationRatioTh pixels are saturated in the
% image
dbg.saturatedPixels = sum(im(:) >= saturationValue);
dbg.saturatedPixelsRatio = dbg.saturatedPixels/numel(im);
notSaturated = dbg.saturatedPixelsRatio < saturationRatioTh;

if exist('outputBinFilesPath','var') && ~isempty(outputBinFilesPath)
    IsntSaturated = notSaturated;
    f_name = sprintf('IsntSaturated');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, IsntSaturated,'uint8');
end
end
