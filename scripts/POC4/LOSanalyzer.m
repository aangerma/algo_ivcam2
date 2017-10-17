function [ res ] = LOSanalyzer( ivsFilename, slowChDelay, verbose )
res = struct();

if (nargin < 3)
    verbose = 0;
end

ivs = io.readIVS(ivsFilename);

xy=double(ivs.xy);
slw=ivs.slow;

ir = circshift(slw, slowChDelay);

%% detect scanlines
Y = bitshift(xy(2,:)-min(xy(2,:)),-1);
dY = diff(Y);
DY = conv(dY, ones(1,1001)/1001, 'same');
scan_dir = (DY > 0);
scan_dir = [scan_dir(1) scan_dir];
scan_changes = abs(diff(double(scan_dir)));
nScans = sum(scan_changes)+1;
scan_yIndices = cumsum(scan_changes) + 1;
scan_yIndices = [scan_yIndices(1) scan_yIndices];

% build new coordinates ys : scanline - y 
sy = [Y-min(Y)+1; scan_yIndices];

% build sy IR image
sySize = [max(sy(1,:)) nScans];
syIndices = sub2ind(sySize,sy(1,:),sy(2,:));

%{
% iteration : optimimalitily check
sDelays = 3023:3030;
stdSs = 1:length(sDelays);
stdYs = 1:length(sDelays);
for i = 1:length(sDelays)
	ir = circshift(slw, sDelays(i));
%}

syImg = accumarray(syIndices', ir, [prod(sySize) 1], @mean);
syImg = reshape(syImg, sySize);

% fill a small amount of holes along scanlines
sypImg = padarray(syImg, [1 0], 'replicate', 'both');
sypCol = im2col(sypImg, [3 1], 'sliding');
sypSm = (sypCol(1,:)+sypCol(3,:))/2;
sypImgSm = reshape(sypSm, size(syImg));
syImg(syImg == 0) = sypImgSm(syImg == 0);

% crop to work with the central part only
syCropRect = [150 400 800 1200];
syImgCrop = imcrop(syImg, syCropRect);

% image normalization
h = hist(syImgCrop(:), [0:10:4100]);
hcs = cumsum(h);
hcs = hcs / max(hcs);
irMin = find(hcs > 0.001, 1)*10+1;
irMax = find(hcs > 0.999, 1)*10+1;

syImgNorm = (syImgCrop - irMin) / (irMax - irMin);
syImgNorm(syImgNorm < 0) = 0;
syImgNorm(syImgNorm > 1) = 1;

% compute gradients
syImgGradS = diff(syImgNorm, 1, 2).^2;
syImgGradY = diff(syImgNorm, 1, 1).^2;

stdS = sqrt(sum(syImgGradS(:))/numel(syImgGradS));
stdY = sqrt(sum(syImgGradY(:))/numel(syImgGradY));

score = stdS - stdY;

%{
% iteration : optimimalitily check
stdSs(i) = stdS;
stdYs(i) = stdY;
end
%}

res.xErrorIR = score * 100;

if (verbose)
	figure;
	subplot(1,2,1); imagesc(syImgCrop); colormap gray; axis image; title 'cropped';
	subplot(1,2,2); imagesc(syImgGradS); axis image; title 'x gradient';
	linkaxes;
end

% x monotonicity
syImgX = accumarray(syIndices', xy(1,:), [prod(sySize) 1], @mean);
syImgX = reshape(syImgX, sySize);

% fill a small amount of holes along scanlines
sypImgX = padarray(syImgX, [1 0], 'replicate', 'both');
sypColX = im2col(sypImgX, [3 1], 'sliding');
sypSmX = (sypColX(1,:)+sypColX(3,:))/2;
sypImgSmX = reshape(sypSmX, size(syImgX));
syImgX(syImgX == 0) = sypImgSmX(syImgX == 0);

gradX = diff(syImgX,1,2);
negX = gradX(gradX < 0);
negX = abs(negX(negX > -100));
res.stdMirrorBackDir = std(negX);
res.meanMirrorBackDir = mean(negX);

end

