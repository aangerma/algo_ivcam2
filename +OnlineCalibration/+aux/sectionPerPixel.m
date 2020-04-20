function [sectionMap] = sectionPerPixel(params,sectionRGB)
if exist('sectionRGB','var') && sectionRGB
    res = [params.rgbRes(2) params.rgbRes(1)];
else
    res = params.depthRes;
end
[gridX,gridY] = meshgrid(0:res(2)-1,0:res(1)-1);
gridX = floor(gridX/res(2)*params.numSectionsH);
gridY = floor(gridY/res(1)*params.numSectionsV);

sectionMap = gridY + gridX*params.numSectionsH;
end

