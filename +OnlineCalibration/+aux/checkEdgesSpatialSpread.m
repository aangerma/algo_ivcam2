function [edgesSpread,dbg] = checkEdgesSpatialSpread(sectionMap,res,pixPerSectionTh,minSectionWithEnoughEdges,numSections)
% Check that there are enough Edges in enough locations 
dbg.numPixPerSec = sum(sectionMap == 0:numSections-1);
dbg.numPixPerSecOverArea = dbg.numPixPerSec./prod(res)*numSections;
dbg.numSectionsWithEnoughEdges = dbg.numPixPerSecOverArea > pixPerSectionTh;
edgesSpread = sum(dbg.numSectionsWithEnoughEdges) >= minSectionWithEnoughEdges;
end