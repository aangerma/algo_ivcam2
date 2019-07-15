figure;
load('D:\worksapce\ivcam2\algo_ivcam2\scripts\smearing\frames_noJfilNoRastBilt.mat');
subplot(2,1,1); imagesc(frames(10).z./4); impixelinfo; title('Depth');
load('D:\worksapce\ivcam2\algo_ivcam2\scripts\smearing\frames.mat');
subplot(2,1,2); imagesc(frames(10).i); impixelinfo; title('IR');
linkaxes; 
numPatches = 1;
centerPix = round(ginput(numPatches));
hold on;
plot(centerPix(1),centerPix(2), 'd');
hold off;
patch = frames(10).i(centerPix(2)-1:centerPix(2)+1,centerPix(1)-1:centerPix(1)+1);
figure; imagesc(patch);impixelinfo; title(['IR patch,center point at: (' num2str(centerPix(1)) ',' num2str(centerPix(2)) ']']);
IRSM = uint16([patch(:)',median(patch(:))])*16
% IRSM = [1360   1376   1376   1744   1744   1760   2624   2640   2656   1744];
load('D:\worksapce\ivcam2\algo_ivcam2\scripts\smearing\unitRegs.mat');
lutOut = genRASTbiltSigmoid();
 mLuts.biltSigmoid(40:end) = lutOut.lut(40:end);
[w] = biltW( IRSM , mRegs, mLuts)
figure; imagesc(reshape(w,size(patch))); impixelinfo; title(['Patch bilateral weights, center point at: (' num2str(centerPix(1)) ',' num2str(centerPix(2)) ']']);
