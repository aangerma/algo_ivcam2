AllDist = [];
Alllocs = [];

for idx = 1:5
    fitP =  ptsFit{idx};
    gridSize = darr(idx).grid;
    gridPoints = darr(idx).pts; 
    tileSize = min(sqrt(sum(diff(darr(idx).pts3d).^2,2)));
    
    px = reshape(fitP(:,1),gridSize);
    py = reshape(fitP(:,2),gridSize);
    pz = reshape(fitP(:,3),gridSize);
    
    ptx = gridPoints(:,:,1);
    pty = gridPoints(:,:,2);
    
    [gty, gtx] = ndgrid(0:gridSize(1)-1,0:gridSize(2)-1);
    gty = gty*tileSize;
    gtx = gtx*tileSize;
    gtz = gtx*0;
    % [pmaxSquareL,pmaxSquareA,pEdges,edgErr] = calcMaxSquare(px,py,pz);
    % [gmaxSquareL,gmaxSquareA,gEdges] = calcMaxSquare(gtx,gty,gtz);
    
    distX = sqrt(diff(px,1,2).^2+diff(py,1,2).^2+diff(pz,1,2).^2)-tileSize;
    distY = sqrt(diff(px,1,1).^2+diff(py,1,1).^2+diff(pz,1,1).^2)-tileSize;
    %vpx = vec(ptx(1:end-1,1:end-1));
    %vpy = vec(pty(1:end-1,1:end-1));
    
    locx = movsum(ptx,2,2);
    vpx = locx(2:end,2:end)/2;
    
    locy = movsum(pty,2,1);
    vpy = locy(2:end,2:end)/2;
    
    AllDist = [AllDist;vec(distX(1:end-1,:)), vec(distY(:,1:end-1))];
    Alllocs = [Alllocs;vpx(:) vpy(:)];
end
figure()
for j=1:2
    subplot(2,1,j),plot(Alllocs(:,j),AllDist(:,j),'+r')
end