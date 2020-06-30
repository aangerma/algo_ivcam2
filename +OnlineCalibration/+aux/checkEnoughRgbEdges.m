function [rgbEdgeSpreadValid,dbg] = checkEnoughRgbEdges(rgbEdgeIm,sectionMap,params)
% This function checks that there are enough rgb edges in the image
binEdgeIm = rgbEdgeIm > params.gradRgbTh;
sectionPerEdge = sectionMap(binEdgeIm);
[rgbEdgeSpreadValid,dbg] = OnlineCalibration.aux.checkEdgesSpatialSpread(sectionPerEdge,params.rgbRes,params.pixPerSectionRgbTh,params.minSectionWithEnoughEdges,params.numSections);

end

