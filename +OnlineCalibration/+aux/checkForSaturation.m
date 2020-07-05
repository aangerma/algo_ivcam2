function [notSaturated,dbg] = checkForSaturation(im,saturationValue,saturationRatioTh)
% Checks that no more than saturationRatioTh pixels are saturated in the
% image
dbg.saturatedPixels = sum(im(:) >= saturationValue);
dbg.saturatedPixelsRatio = dbg.saturatedPixels/numel(im);
notSaturated = dbg.saturatedPixelsRatio < saturationRatioTh;
end
