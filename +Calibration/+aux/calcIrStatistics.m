function irStat = calcIrStatistics(ir, corners)
ir = single(ir);
% reshaping
cbSize = [20,28];
if (size(corners,1) ~= prod(cbSize))
    irStat = struct('mean',NaN,'std',NaN,'tiles',[],'nPix',0);
    return
end
cornersX = reshape(corners(:,1), cbSize);
cornersY = reshape(corners(:,2), cbSize);

% defining white tiles closest to CB center
xBorders = [14,15; % top
            13,14; % left
            15,16; % right
            14,15]; % bottom
yBorders = [9,10; % top
            10,11; % left
            10,11; % right
            11,12]; % bottom

% processable pixels identification
[pixX, pixY] = meshgrid(1:size(ir,2), 1:size(ir,1));
idcs = false(size(pixX));
margin = 0.2; % unprocessed pixels (on each side) w.r.t. tile size
tiles = 1:size(xBorders,1);
for iTile = 1:size(xBorders,1)
    tileX = cornersX(yBorders(iTile,:), xBorders(iTile,:));
    tileY = cornersY(yBorders(iTile,:), xBorders(iTile,:));
    if any(isnan(tileX(:))) || any(isnan(tileY(:))) % skip processing tile
        tiles(iTile) = 0;
        continue
    end
    sizeX = diff(tileX, [], 2);
    sizeY = diff(tileY, [], 1);
    processedX = tileX + margin*sizeX*[1,-1];
    processedY = tileY + margin*[1;-1]*sizeY;
    idcs = idcs | inpolygon(pixX, pixY, processedX([1,2,4,3]), processedY([1,2,4,3]));
end
processedIR = ir(idcs);
tiles = tiles(tiles>0);

% statistics extraction
irStat.mean = mean(processedIR);
irStat.std = std(processedIR);
irStat.tiles = tiles;
irStat.nPix = sum(idcs(:)>0);

end

