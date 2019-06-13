if ~exist('hw','var')
    hw = HWinterface;
    %hw.cmd('ALGO_THERMLOOP_EN 10');
    hw.cmd('dirtybitbypass');
    hw.getFrame();
    pause(5);
    
end

params = Validation.aux.defaultMetricsParams();
params.verbose = 0;
params.expectedGridSize = [];
params.calibrationTargetIV2 = 1;
params.camera.K = hw.getIntrinsics;
params.camera.zMaxSubMM = double(hw.z2mm);
params.target.squareSize = 30;


%dsmScaleY = typecast(hw.read('EXTLdsmYscale'),'single');
if 0
    %hw.setReg('EXTLdsmYscale',dsmScaleY*1);
    %hw.setReg('EXTLdsmXscale',dsmScaleX*1);
    hw.setReg('DIGGsphericalEn',false);
    hw.setReg('DESTdepthAsRange',false);
    hw.setReg('DESTbaseline2',single(100));
    hw.setReg('DESTbaseline$',single(-10));
    
    %hw.setReg('EXTLdsmXscale',dsmScaleX*1);
    hw.setReg('DIGGsphericalEn',true);
    hw.setReg('DESTdepthAsRange',true);
    hw.setReg('DESTbaseline2',single(0));
    hw.setReg('DESTbaseline$',single(0));
    
    
    hw.cmd('ALGO_THERMLOOP_EN 10');
    
    hw.cmd('ALGO_THERMLOOP_EN 0');
    hw.setReg('DESTtmptrOffset',single(0));
    
    
    hw.shadowUpdate;
    
end


AllDist = [];
Alllocs = [];
for k= 1:1
    if 1
        frame = Calibration.aux.CBTools.showImageRequestDialog(hw,1,[],'DFZ Validation image');
        frame = hw.getFrame;
    else
    %pause(1)
        frame = hw.getFrame(30,1);
    end
    %z = double(cat(3,frames(:).z));
    %z(z ==0) = NaN;
    %frame.z = nanmedian(z,3);
    %frame.i = frames(1).i;
    %fprintf('Temperature: %2.4g\n',hw.getLddTemperature());
    frame = rotFrame180(frame);
    warning off;
    [score, results,dbgData] = Validation.metrics.geomUnproject(frame,params);
    [scoreGID, resultsGID,dbgDataGID] = Validation.metrics.gridInterDist(frame,params);
    
    warning on;
    %[score, resultsLos,dbgData] = Validation.metrics.losGridDrift(frames,params);
    
    
    px = reshape(dbgData.vertices(:,1),dbgData.gridSize);
    py = reshape(dbgData.vertices(:,2),dbgData.gridSize);
    pz = reshape(dbgData.vertices(:,3),dbgData.gridSize);
    ptx = reshape(dbgData.gridPoints(:,1),dbgData.gridSize);
    pty = reshape(dbgData.gridPoints(:,2),dbgData.gridSize);
    [gty, gtx] = ndgrid(0:dbgData.gridSize(1)-1,0:dbgData.gridSize(2)-1);
    gty = gty*params.target.squareSize;
    gtx = gtx*params.target.squareSize;
    gtz = gtx*0;
    [pmaxSquareL,pmaxSquareA,pEdges,edgErr] = calcMaxSquare(px,py,pz);
    [gmaxSquareL,gmaxSquareA,gEdges] = calcMaxSquare(gtx,gty,gtz);
    
    distX = sqrt(diff(px,1,2).^2+diff(py,1,2).^2+diff(pz,1,2).^2)-params.target.squareSize;
    distY = sqrt(diff(px,1,1).^2+diff(py,1,1).^2+diff(pz,1,1).^2)-params.target.squareSize;
    %vpx = vec(ptx(1:end-1,1:end-1));
    %vpy = vec(pty(1:end-1,1:end-1));
    
    locx = movsum(ptx,2,2);
    vpx = locx(2:end,2:end)/2;
    
    locy = movsum(pty,2,1);
    vpy = locy(2:end,2:end)/2;
    
    AllDist = [AllDist;vec(distX(1:end-1,:)), vec(distY(:,1:end-1))];
    Alllocs = [Alllocs;vpx(:) vpy(:)];
    
    errs = sqrt((vec(distX(1:end-1,:)).^2 + vec(distY(:,1:end-1)).^2));
    %maxDist = prctile(sqrt((vec(distX(1:end-1,:)).^2 + vec(distY(:,1:end-1)).^2)),95);
    %medDist = median(sqrt((vec(distX(1:end-1,:)).^2 + vec(distY(:,1:end-1)).^2)));
    maxDist = prctile(errs, 95);
    medDist = prctile(errs, 50);
    
    imSize  = [640 360];
    [yg,xg]=ndgrid(0:imSize(2)-1,0:imSize(1)-1);
    filt = fspecial('gaussian', [15, 15], 10);
    if k < 2
        
        figure(4)
        F = scatteredInterpolant(vec(ptx(1:end-1,1:end-1)),vec(pty(1:end-1,1:end-1)),vec(distX(1:end-1,:)), 'natural');
        
        vq = F(xg, yg);
        imagesc(vq);colormap jet;
        
        figure(5)
        plot3(dbgData.projVertices(:,1),dbgData.projVertices(:,2),dbgData.projVertices(:,3),'ob',...
            dbgData.vertices(:,1),dbgData.vertices(:,2),dbgData.vertices(:,3),'+r')
        %plot3(dbgData.vertices(:,1),dbgData.vertices(:,2),dbgData.vertices(:,3),'+r')
        axis xy;
    end
    
    
    figure(3);
    imagesc(frame(1).i);colormap gray
    hold on;
    quiver(vec(vpx),vec(vpy),vec(distX(1:end-1,:)),vec(distY(:,1:end-1)),'r')
    hold off;
    title(sprintf('Max Distortion: %2.4g mm  MAE: %2.4g GID: %2.4g Temp %2.4g',maxDist,medDist,scoreGID, hw.getLddTemperature))
    repPos = [ptx(1,1) pty(1,1);ptx(1,end) pty(1,end);ptx(end,end) pty(end,end);ptx(end,1) pty(end,1)];
    drawpolygon('Position',repPos,'FaceAlpha',0);
    
    for i = 0:3
        rot = mod(i,2)*90;
        offX = mod(i,2)*10.*(mod(floor(i/2),2)*-2 +1);
        offY = mod(i+1,2)*10.*(mod(floor(i/2),2)*2 -1);
        text((repPos(mod(i+1,4)+1,1) + repPos(mod(i,4)+1,1))/2+offX,...
            (repPos(mod(i+1,4)+1,2) + repPos(mod(i,4)+1,2))/2+offY,...
            sprintf('%2.4g GT %2.4g',pEdges(i+1),gEdges(i+1)),...
            'Rotation',rot,'Color','red','FontSize',14)
    end
end
figure(6);
for j=1:2
subplot(2,1,j),plot(Alllocs(:,j),AllDist(:,j),'+r')
end
