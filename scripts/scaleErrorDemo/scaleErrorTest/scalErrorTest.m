unit='F9140336'; 
dataPath=strcat('X:\Users\hila\XGA\xgaCalib\F9140336\XGA\checkersIm\data.mat');
load(dataPath);
%%
savePath=strcat('X:\Users\hila\XGA\xgaCalib\F9140336\XGA\checkersIm',unit); 
mkdir(savePath); 
params = Validation.aux.defaultMetricsParams();
params.verbose = 0;
params.expectedGridSize = [];
params.calibrationTargetIV2 = 1;
params.camera.K = K;
params.camera.zMaxSubMM = double(z2mm);
params.target.squareSize = 30;

TestResult=[]; 
TestResult.unit=unit; 
% frame num
  frames=frames(15); 
frames = rotFrame180(frames);
%% RUN METRICS
[score, results,dbgData] = Validation.metrics.geomUnproject(frames,params);
TestResult.geomUnproject_score=score; 
TestResult.geomUnproject_results=results; 

[scoreGID, resultsGID,dbgDataGID] = Validation.metrics.gridInterDist(frames,params);
TestResult.GID_score=scoreGID; 
TestResult.GID_results=resultsGID; 
%% SCALE ERROR

AllDist = [];
Alllocs = [];
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

distH = sqrt(diff(px,1,2).^2+diff(py,1,2).^2+diff(pz,1,2).^2)-params.target.squareSize;
distV = sqrt(diff(px,1,1).^2+diff(py,1,1).^2+diff(pz,1,1).^2)-params.target.squareSize;
ratioH=sqrt(diff(px,1,2).^2+diff(py,1,2).^2+diff(pz,1,2).^2)/params.target.squareSize-1; % % error
ratioV=sqrt(diff(px,1,1).^2+diff(py,1,1).^2+diff(pz,1,1).^2)/params.target.squareSize-1;
%vpx = vec(ptx(1:end-1,1:end-1));
%vpy = vec(pty(1:end-1,1:end-1));

locx = movsum(ptx,2,2);
vpx = locx(2:end,2:end)/2;

locy = movsum(pty,2,1);
vpy = locy(2:end,2:end)/2;

AllDist = [AllDist;vec(distH(1:end-1,:)), vec(distV(:,1:end-1))];
Alllocs = [Alllocs;vpx(:) vpy(:)];

errs = sqrt((vec(distH(1:end-1,:)).^2 + vec(distV(:,1:end-1)).^2));
%maxDist = prctile(sqrt((vec(distX(1:end-1,:)).^2 + vec(distY(:,1:end-1)).^2)),95);
%medDist = median(sqrt((vec(distX(1:end-1,:)).^2 + vec(distY(:,1:end-1)).^2)));
maxDist = prctile(errs, 95);
medDist = prctile(errs, 50);
TestResult.maxDist=maxDist;
TestResult.medDist=medDist;

imSize  = fliplr(size(frames(1).i));
[yg,xg]=ndgrid(0:imSize(2)-1,0:imSize(1)-1);
filt = fspecial('gaussian', [15, 15], 10);

%% heat map- Error [mm]
fig1 = figure('NumberTitle', 'off', 'Name','heat map- Error [mm]' ,'Position', get(0, 'Screensize'));
subplot(1,2,1); 
F = scatteredInterpolant(vec(ptx(1:end-1,1:end-1)),vec(pty(1:end-1,1:end-1)),vec(distH(1:end-1,:)), 'natural','none');
vq = F(xg, yg);
imagesc(vq);colormap jet;
colorbar; 
title('Horizontal scale error ( p2p distance-GT distance) [mm]'); 
subplot(1,2,2); 
F = scatteredInterpolant(vec(ptx(1:end-1,1:end-1)),vec(pty(1:end-1,1:end-1)),vec(distV(:,1:end-1)), 'natural','none');
vq = F(xg, yg);
imagesc(vq);colormap jet;
colorbar; 
title('Vertical scale error ( p2p distance-GT distance) [mm]'); 
    saveas(fig1,[savePath '\heatMapScaleErr_mm'], 'png');
    saveas(fig1,[savePath '\heatMapScaleErr_mm'], 'fig');
%% heat map- Error [ratio-1]
fig2 = figure('NumberTitle', 'off', 'Name','heat map- Error ratio' ,'Position', get(0, 'Screensize'));
subplot(1,2,1); 
F = scatteredInterpolant(vec(ptx(1:end-1,1:end-1)),vec(pty(1:end-1,1:end-1)),100*vec(ratioH(1:end-1,:)), 'natural','none');
vq = F(xg, yg);
imagesc(vq);colormap jet;
colorbar; 
title('Horizontal scale error ( (p2p distance/GT distance)-1 ) [%]'); 
subplot(1,2,2); 
F = scatteredInterpolant(vec(ptx(1:end-1,1:end-1)),vec(pty(1:end-1,1:end-1)),100*vec(ratioV(:,1:end-1)), 'natural','none');
vq = F(xg, yg);
imagesc(vq);colormap jet;
colorbar; 
title('Vertical scale error ( (p2p distance/GT distance)-1 ) [%])'); 
    saveas(fig2,[savePath '\heatMapScaleErr_ratio'], 'png');
    saveas(fig2,[savePath '\heatMapScaleErr_ratio'], 'fig');
%
%%

h=figure;
plot3(dbgData.projVertices(:,1),dbgData.projVertices(:,2),dbgData.projVertices(:,3),'ob',...
    dbgData.vertices(:,1),dbgData.vertices(:,2),dbgData.vertices(:,3),'+r')
%plot3(dbgData.vertices(:,1),dbgData.vertices(:,2),dbgData.vertices(:,3),'+r')
axis xy;grid on; legend('projVertices','vertices'); 
saveas(h,[savePath '\projVertices_vs_vertices'], 'png');
    saveas(h,[savePath '\projVertices_vs_vertices'], 'fig');

%%
h1=figure;
imagesc(frames(1).i);colormap gray
hold on;
quiver(vec(vpx),vec(vpy),vec(distH(1:end-1,:)),vec(distV(:,1:end-1)),'r')
hold off;
title(sprintf('Max Distortion: %2.4g mm  MAE: %2.4g GID: %2.4g ',maxDist,medDist,scoreGID))
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
saveas(h1,[savePath '\quiverMap'], 'png');
    saveas(h1,[savePath '\quiverMap'], 'fig');
%%
h2=figure;
for j=1:2
    subplot(2,1,j),plot(Alllocs(:,j),AllDist(:,j),'+r')
end
subplot(2,1,1); title('Horizontal scale error [mm]'); 
subplot(2,1,2); title('Vertical scale error [mm]'); 

saveas(h2,[savePath '\DistvsLocs'], 'png');
    saveas(h2,[savePath '\DistvsLocs'], 'fig');

%% 
save([savePath '\TestRes'],'TestResult');