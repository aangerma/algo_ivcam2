function [edgesDirSpread,directionData,dbg] = checkEdgesDirSpread(directions,xim,yim,res,params,outputBinFilesPath)
% Enough Edges in enough directions and Std Per Dir (weights will be
% normalized by direction,Normalize by weights is done in a seperate
% function)

% Enough Edges Per Dir:
nDirs = 4;
dbg.edgesAmountPerDirections = sum(directions == 1:nDirs,1);
dbg.edgesAmountPerDirectionsNorm = dbg.edgesAmountPerDirections/prod(res);
dbg.directionsWithEnoughEdges = dbg.edgesAmountPerDirectionsNorm > params.edgesPerDirectionRatioTh;
dbg.numFullDirections = sum(dbg.directionsWithEnoughEdges);
dbg.enoughEdgesPerDir = dbg.numFullDirections >= params.minimalFullDirections;

% Std Check for valid directions
dirVecs = [1,0; 1/sqrt(2),1/sqrt(2); 0,1; -1/sqrt(2),1/sqrt(2)]';
stdPerDir = zeros(1,nDirs);
diagLength = sqrt(res(1)^2+res(2)^2);
for i = 1:nDirs
    if sum(directions == i) ~= 0
        xyDir = [xim(directions == i),yim(directions == i)];
        stdPerDir(i) = std(xyDir*dirVecs(:,i))./diagLength;
        %                 figure;
        %                 plot(xyDir(:,1),xyDir(:,2),'*')
    end
end
dbg.stdPerDir = stdPerDir;
dbg.stdBiggerThanTh = stdPerDir > params.dirStdTh;
directionData.validDirections = dbg.stdBiggerThanTh & dbg.directionsWithEnoughEdges;
edgesDirSpread = sum(directionData.validDirections) >= params.minimalFullDirections;
if params.requireOrthogonalValidDirs % If true, we need to have two valid directions that are orthogonal
    orthogonalValidDirs = any(directionData.validDirections(1:2) & directionData.validDirections(3:4));
    edgesDirSpread = edgesDirSpread && orthogonalValidDirs;
end

directionData.edgesPerDirection = dbg.edgesAmountPerDirections;

if exist('outputBinFilesPath','var') && ~isempty(outputBinFilesPath)
    Spread = edgesDirSpread;
    f_name = sprintf('DirSpread');
    OnlineCalibration.aux.saveBinImage(outputBinFilesPath, f_name, Spread,'uint8');
end
end

% for i = 1:4
%    plot(xim(directions == i)+1,yim(directions == i)+1,'*') 
%    hold on
% end
