% load('D:\worksapce\ivcam2\algo_ivcam2\scripts\smearing\forPostProc.mat');
path = 'X:\Users\mkiperwa\smearing';
scene = 'scene9'; %8-15
savePath = [path '\results\' scene];

load([path '\scenes\' scene '.mat']);

Iir = frames(10).i;
params = struct('IR_grad_thresh', 180, 'ir_thresh', 190, 'neighborPix', 8, 'dz_around_edge_th', 45, 'dz_in_neighborPix_th', 100);
% IR_grad_thresh = 100;
% ir_thresh = 170;%130; %Condition #2
% neighborPix = 7; %For condition #3 and #5
% dz_around_edge_th = 30; %For condition #4
% dz_in_neighborPixx_th = 100;

verbose = false;

%%
% IR and Depth and their x,y gradients
[Gx_ir,Gy_ir] = imgradientxy(Iir);
Idepth = double(frames(10).z./4);
[Gx_z,Gy_z] = imgradientxy(Idepth);
if verbose
    figure;
    subplot(2,3,1); imagesc(Iir); title('IR'); impixelinfo;
    subplot(2,3,2); imagesc(Gx_ir); title('IR - gradient in x direction'); impixelinfo;
    subplot(2,3,3); imagesc(Gy_ir); title('IR - gradient in y direction'); impixelinfo;linkaxes;
    subplot(2,3,4); imagesc(frames(10).z./4); title('Depth'); impixelinfo;
    subplot(2,3,5); imagesc(Gx_z); title('Depth - gradient in x direction'); impixelinfo;
    subplot(2,3,6); imagesc(Gy_z); title('Depth - gradient in y direction'); impixelinfo;linkaxes;
end



[IdepthCorrectedX,IconfCorrectedX] = ivalidateSmear('x',Iir,Gx_ir,Idepth,frames(10).c,params,verbose);
[IdepthCorrectedY,IconfCorrectedY] = ivalidateSmear('y',Iir,Gy_ir,Idepth,frames(10).c,params,verbose);

figure; 
subplot(2,2,1); imagesc(Iir); title('IR'); impixelinfo;
subplot(2,2,2); imagesc(frames(10).z./4); title('Depth'); impixelinfo;
subplot(2,2,3); imagesc(IdepthCorrectedX); title('Corrected depth - x direction'); impixelinfo;linkaxes;
subplot(2,2,4); imagesc(IdepthCorrectedY); title('Corrected depth - y direction'); impixelinfo;linkaxes;
saveas(gcf,[savePath '_eachAxis.png']);

Icorrected = IdepthCorrectedX;
Icorrected(IdepthCorrectedY==0) = 0;
%%
figure;
subplot(3,1,1); imagesc(Iir); title('IR'); impixelinfo;
subplot(3,1,2); imagesc(frames(10).z./4); title('Depth'); impixelinfo;
subplot(3,1,3); imagesc(Icorrected); title('Corrected depth'); impixelinfo;linkaxes;
saveas(gcf,[savePath '_results.png']);

% figure;cdfplot(frames(10).z(:)./4);
% subplot(4,1,4); imagesc(ir_edge_x); title('Edges higher than threshold'); impixelinfo;linkaxes;
Idepth_orig = single(frames(10).z./4);

Idiff = Idepth_orig-single(Icorrected);
figure; imagesc(Idiff); title(['Difference image Iorig-Icorrected. Number of different pixels  = ' num2str(sum(Idiff(:)>0))]);
saveas(gcf,[savePath '_diff.png']);

function [IdepthCorrected,IconfCorrected] = ivalidateSmear(CorrectDir,Iir,G_ir,Idepth,Iconf,params,verbose)
switch CorrectDir
    case 'x'
        cannyDir = 'horizontal';
        sizeOfAxisDir = size(Iir,2);
    case 'y'
        cannyDir = 'vertical';
        sizeOfAxisDir = size(Iir,1);
    otherwise
        error('No such direction implemented!');
end
%%
% Find edges of interest - condition #1
ir_edge = edge(Iir,'Canny',cannyDir,[0.2,0.5]);
if verbose
    figure;
    subplot(3,1,1); imagesc(Iir); title('IR'); impixelinfo;
    subplot(3,1,2); imagesc(G_ir); title(['IR - gradient in ' CorrectDir ' direction']); impixelinfo;
    subplot(3,1,3); imagesc(ir_edge); title(['IR - edges in ' CorrectDir ' direction']); impixelinfo;linkaxes;
end
%%
% Discard threshold where gradient is too low
% ir_edge(abs(G_ir.*ir_edge) < max(G_ir(:))*params.IR_grad_thresh) = 0;
ir_edge(abs(G_ir.*ir_edge) < params.IR_grad_thresh) = 0;
if verbose
    figure; subplot(2,1,1); imagesc(Iir); title('IR'); impixelinfo;
    subplot(2,1,2); imagesc(ir_edge); title('Edges higher than threshold'); impixelinfo;linkaxes;
end
% We are intrested only in pixels that are whithin the IR edge neighborhood
% Condition #3
pixs2CheckByNeighbor = findPixByNeighbor(ir_edge,params.neighborPix,CorrectDir);
Idebug = Iir; Idebug(~pixs2CheckByNeighbor) = 0;
if verbose
    figure; subplot(2,1,1); imagesc(Iir); title('IR'); impixelinfo;
    subplot(2,1,2); imagesc(Idebug); title('Area to check by IR edge neighborhood'); impixelinfo;linkaxes;
end
% Show IR on the edges I found
IrOnEdges = Iir;
IrOnEdges(~ir_edge) = 0;
if verbose
    figure; subplot(2,1,1); imagesc(Iir); title('IR'); impixelinfo;
    subplot(2,1,2); imagesc(IrOnEdges); title('IrOnEdges'); impixelinfo;linkaxes;
end
%%
%{
% For debug - show IR max-min on different scenes
load('X:\Users\mkiperwa\smearing\IR_differentDists\far1.mat');
load('X:\Users\mkiperwa\smearing\IR_differentDists\far2.mat');
load('X:\Users\mkiperwa\smearing\IR_differentDists\close1.mat');
load('X:\Users\mkiperwa\smearing\IR_differentDists\close2.mat');

figure; subplot(2,2,1); imagesc(framesClose1(10).i); title(['IR - close 1. Median = ' num2str(median(framesClose1(10).i(:))) '. Max(IR)-Min(IR) = ' num2str(max(framesClose1(10).i(:))-min(framesClose1(10).i(:)))]); impixelinfo;
subplot(2,2,2); imagesc(framesClose2(10).i); title(['IR - close 2. Median = ' num2str(median(framesClose2(10).i(:))) '. Max(IR)-Min(IR) = ' num2str(max(framesClose2(10).i(:))-min(framesClose2(10).i(:)))]); impixelinfo;
subplot(2,2,3); imagesc(framesFar1(10).i); title(['IR - far 1. Median = ' num2str(median(framesFar1(10).i(:))) '. Max(IR)-Min(IR) = ' num2str(max(framesFar1(10).i(:))-min(framesFar1(10).i(:)))]); impixelinfo;
subplot(2,2,4); imagesc(framesFar2(10).i); title(['IR - far 2. Median = ' num2str(median(framesFar2(10).i(:))) '. Max(IR)-Min(IR) = ' num2str(max(framesFar2(10).i(:))-min(framesFar2(10).i(:)))]); impixelinfo;
%}
%%
% Adding condition #5 and condition #2
IdepthNan = Idepth;
IdepthNan(IdepthNan == 0) = nan;

pixs2Check = ~isnan(IdepthNan) & Iir<params.ir_thresh & pixs2CheckByNeighbor;
Idebug = Iir; Idebug(~pixs2Check) = 0;
if verbose
    figure; subplot(3,1,1); imagesc(Iir); title('IR'); impixelinfo;
    subplot(3,1,2); imagesc(Idebug); title('Ipixs2Check'); impixelinfo;
    subplot(3,1,3);imagesc(Idepth); title('Depth'); impixelinfo;linkaxes;
end
%%
IdepthCorrected = Idepth;
IconfCorrected = Iconf;
for ix_y = 1:size(ir_edge,1)
    for ix_x = 1:size(ir_edge,2)
        if ~pixs2Check(ix_y,ix_x)
            continue;
        end
        [dz_around_edge,closestEdgeIx] = calcDzAroundClosestEdge(IdepthNan,ix_x,ix_y,ir_edge,CorrectDir);
        if dz_around_edge > params.dz_around_edge_th % Condition #4
            continue;
        end
        [depthFromEdge,maxDepthFromEdge,maxDepthepthInd] = calcDepthFromEdge(IdepthNan,Iir,ix_x,ix_y,closestEdgeIx,sizeOfAxisDir,CorrectDir,params.neighborPix);
        if any(isnan(depthFromEdge))
            IdepthCorrected(ix_y,ix_x) = 0;
            IconfCorrected(ix_y,ix_x) = 0;
            continue;
        end
        if maxDepthFromEdge>params.dz_in_neighborPix_th && Iir(ix_y,ix_x) < Iir(maxDepthepthInd(1),maxDepthepthInd(2))
           IdepthCorrected(ix_y,ix_x) = 0;
           IconfCorrected(ix_y,ix_x) = 0;
        end
    end
end
end

%%

function [pixs2CheckByNeighbor] = findPixByNeighbor(ir_edge,neighborPix,axisDir)
pixs2CheckByNeighbor = false(size(ir_edge));
for ix_y = 1:size(ir_edge,1)
    for ix_x = 1:size(ir_edge,2)
        if ir_edge(ix_y,ix_x)
            if strcmp(axisDir,'y')
                pixs2CheckByNeighbor(max(1,ix_y-ceil(neighborPix/2)):min(ix_y+ceil(neighborPix/2),size(ir_edge,1)),ix_x) = true;
            else
                pixs2CheckByNeighbor(ix_y,max(1,ix_x-ceil(neighborPix/2)):min(ix_x+ceil(neighborPix/2),size(ir_edge,2))) = true;
            end
        end
    end
end
end

function [dz_around_edge,closestEdgeIx] = calcDzAroundClosestEdge(Idepth,ix_x,ix_y,ir_edge,axisDir)
if strcmp(axisDir,'y')
    edgedInDir = find(ir_edge(:,ix_x));
    [~,iMin] = min(abs(edgedInDir - ix_y));
    sizeOfAxisDir = size(ir_edge,1);
else
    edgedInDir = find(ir_edge(ix_y,:));
    [~,iMin] = min(abs(edgedInDir - ix_x));
    sizeOfAxisDir = size(ir_edge,2);
end
closestEdgeIx = edgedInDir(iMin);
beforEdgeIx = max(1,closestEdgeIx-1);
afterEdgeIx = min(sizeOfAxisDir,closestEdgeIx+1);
if strcmp(axisDir,'y')
    dz_around_edge = abs(Idepth(beforEdgeIx,ix_x) - Idepth(afterEdgeIx,ix_x));
else
    dz_around_edge = abs(Idepth(ix_y,beforEdgeIx) - Idepth(ix_y,afterEdgeIx));
end
end

function [depthFromEdge,maxDepthFromEdge,maxDepthepthInd] = calcDepthFromEdge(Idepth,Iir,ix_x,ix_y,closestEdgeIx,sizeOfAxisDir,axisDir,neighborPix)
if strcmp(axisDir,'y')
    dx_from_edge = ix_y - closestEdgeIx;
    if dx_from_edge == 0
        if Iir(min(ix_y+2,sizeOfAxisDir), ix_x) > Iir(max(ix_y-2,1), ix_x)
            dirSign = -1;
        else
            dirSign = 1;
        end
    else
        dirSign = sign(dx_from_edge);
    end
    ind = ix_y:dirSign:min(max(ix_y + dirSign*(neighborPix - abs(dx_from_edge)),1),sizeOfAxisDir);
    depthFromEdge = abs(Idepth(ind, ix_x)-Idepth(ix_y, ix_x));
else
    dx_from_edge = ix_x - closestEdgeIx;
    if dx_from_edge == 0
        if Iir(ix_y,min(ix_x+2,sizeOfAxisDir)) > Iir(ix_y,max(ix_x-2,1))
            dirSign = -1;
        else
            dirSign = 1;
        end
    else
        dirSign = sign(dx_from_edge);
    end
    ind = ix_x:dirSign:min(max(ix_x + dirSign*(neighborPix - abs(dx_from_edge)),1),sizeOfAxisDir);
    depthFromEdge = (abs(Idepth(ix_y, ind)-Idepth(ix_y, ix_x)));
end
[maxDepthFromEdge, iMax] = nanmax(depthFromEdge);
if strcmp(axisDir,'y')
    maxDepthepthInd = [ind(iMax), ix_x];
else
    maxDepthepthInd = [ix_y,ind(iMax)];
end
end