% load('D:\worksapce\ivcam2\algo_ivcam2\scripts\smearing\forPostProc.mat');
load('X:\Users\mkiperwa\smearing\scenes\scene10.mat');

Iir = frames(10).i;
IR_grad_thresh = 100;
ir_thresh = 170;%130; %Condition #2
neighborPix = 7; %For condition #3 and #5
dz_around_edge_x_th = 30; %For condition #4
dz_in_neighborPixx_th = 100;

%%
% IR and Depth and their x,y gradients
[Gx_ir,Gy_ir] = imgradientxy(Iir);
Idepth = double(frames(10).z./4);
Idepth(Idepth == 0) = nan;
[Gx_z,Gy_z] = imgradientxy(Idepth);
figure;
subplot(2,3,1); imagesc(Iir); title('IR'); impixelinfo;
subplot(2,3,2); imagesc(Gx_ir); title('IR - gradient in x direction'); impixelinfo;
subplot(2,3,3); imagesc(Gy_ir); title('IR - gradient in y direction'); impixelinfo;linkaxes;
subplot(2,3,4); imagesc(frames(10).z./4); title('Depth'); impixelinfo;
subplot(2,3,5); imagesc(Gx_z); title('Depth - gradient in x direction'); impixelinfo;
subplot(2,3,6); imagesc(Gy_z); title('Depth - gradient in y direction'); impixelinfo;linkaxes;
%%
% Find edges of interest - condition #1
ir_edge_x = edge(Iir,'Canny','horizontal',[0.01,0.1]);
figure;
subplot(3,1,1); imagesc(Iir); title('IR'); impixelinfo;
subplot(3,1,2); imagesc(Gx_ir); title('IR - gradient in x direction'); impixelinfo;
subplot(3,1,3); imagesc(ir_edge_x); title('IR - edges in x direction'); impixelinfo;linkaxes;
%%
% Discard threshold where gradient is too low
ir_edge_x(abs(Gx_ir.*ir_edge_x) < IR_grad_thresh) = 0;
figure; subplot(2,1,1); imagesc(Iir); title('IR'); impixelinfo;
subplot(2,1,2); imagesc(ir_edge_x); title('Edges higher than threshold'); impixelinfo;linkaxes;
% We are intrested only in pixels that are whithin the IR edge neighborhood
% Condition #3
pixs2CheckByNeighbor = false(size(ir_edge_x));
for ix_y = 1:size(ir_edge_x,1)
    for ix_x = 1:size(ir_edge_x,2)
        if ir_edge_x(ix_y,ix_x)
            pixs2CheckByNeighbor(ix_y,max(1,ix_x-ceil(neighborPix/2)):min(ix_x+ceil(neighborPix/2),size(ir_edge_x,2))) = true;
        end
    end
end
Idebug = Iir; Idebug(~pixs2CheckByNeighbor) = 0;
figure; subplot(2,1,1); imagesc(Iir); title('IR'); impixelinfo;
subplot(2,1,2); imagesc(Idebug); title('Area to check by IR edge neighborhood'); impixelinfo;linkaxes;
% Show IR on the edges I found
IrOnEdges = Iir;
IrOnEdges(~ir_edge_x) = 0;
figure; subplot(2,1,1); imagesc(Iir); title('IR'); impixelinfo;
subplot(2,1,2); imagesc(IrOnEdges); title('IrOnEdges'); impixelinfo;linkaxes;
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
pixs2Check = ~isnan(Idepth) & Iir<ir_thresh & pixs2CheckByNeighbor;
Idebug = Iir; Idebug(~pixs2Check) = 0;
figure; subplot(3,1,1); imagesc(Iir); title('IR'); impixelinfo;
subplot(3,1,2); imagesc(Idebug); title('Ipixs2Check'); impixelinfo;
subplot(3,1,3);imagesc(frames(10).z./4); title('Depth'); impixelinfo;linkaxes;

%%
ixEdges = find(ir_edge_x);
ixPixs2Check = find(pixs2Check);
Iir_single = single(Iir);
IdepthCorrected = frames(10).z./4;
IconfCorrected = frames(10).c;
for ix_y = 1:size(ir_edge_x,1)
    for ix_x = 1:size(ir_edge_x,2)
        if ~pixs2Check(ix_y,ix_x)
            continue;
        end
        edgedInXdir = find(ir_edge_x(ix_y,:));
        [~,ixMin] = min(abs(edgedInXdir - ix_x));
        closestEdgeIx = edgedInXdir(ixMin);
        beforEdgeIx = max(1,closestEdgeIx-1);
        afterEdgeIx = min(size(ir_edge_x,2),closestEdgeIx+1);
        dz_around_edge_x = abs(Idepth(ix_y,beforEdgeIx) - Idepth(ix_y,afterEdgeIx));
        if dz_around_edge_x > dz_around_edge_x_th % Condition #4
            continue;
        end
        dx_from_edge = ix_x - closestEdgeIx;
        if dx_from_edge == 0
            depthFromEdge = abs(Idepth(ix_y, ix_x:1:min(max(ix_x + neighborPix - abs(dx_from_edge),1),size(ir_edge_x,2)))-Idepth(ix_y, ix_x));
            depthFromEdge = max([depthFromEdge,abs(Idepth(ix_y, ix_x:-1:min(max(ix_x - neighborPix - abs(dx_from_edge),1),size(ir_edge_x,2)))-Idepth(ix_y, ix_x))]);
        else
            depthFromEdge = abs(Idepth(ix_y, ix_x: sign(dx_from_edge):min(max(ix_x + sign(dx_from_edge)*(neighborPix - abs(dx_from_edge)),1),size(ir_edge_x,2)))-Idepth(ix_y, ix_x));
        end
        if any(isnan(depthFromEdge) | depthFromEdge>dz_in_neighborPixx_th)
            IdepthCorrected(ix_y,ix_x) = 0;
            IconfCorrected(ix_y,ix_x) = 0;
        end
    end
end

figure;
subplot(3,1,1); imagesc(Iir); title('IR'); impixelinfo;
subplot(3,1,2); imagesc(frames(10).z./4); title('Depth'); impixelinfo;
subplot(3,1,3); imagesc(IdepthCorrected); title('Corrected depth'); impixelinfo;linkaxes;
% figure;cdfplot(frames(10).z(:)./4);
% subplot(4,1,4); imagesc(ir_edge_x); title('Edges higher than threshold'); impixelinfo;linkaxes;
Idepth_orig = single(frames(10).z./4);

Idiff = Idepth_orig-single(IdepthCorrected);
figure; imagesc(Idiff); title(['Difference image Iorig-Icorrected. Number of different pixels  = ' num2str(sum(Idiff(:)>0))]);
