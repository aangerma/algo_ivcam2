function [hError, checkerPoints] = edgeUnifomity(ir,hw,vw)
[imagePoints,boardSize] = detectCheckerboardPoints(ir);
if isempty(imagePoints)
    error('cant find checker points')
elseif size(imagePoints,1) < 100
    figure(12358)
    imagesc(ir);colormap gray
    hold on
    plot(imagePoints(:,1),imagePoints(:,2),'*')
    hold off
    error('cant find enough checker points')
end
checkerPoints.x = round(reshape(imagePoints(:,1),boardSize-1));
checkerPoints.y = round(reshape(imagePoints(:,2),boardSize-1));

if imagePoints(1,1) > imagePoints(end,1)
    checkerPoints.x = checkerPoints.x(end:-1:1,:);
    checkerPoints.y = checkerPoints.y(end:-1:1,:);
end
if imagePoints(1,2) > imagePoints(end,2)
    checkerPoints.x = checkerPoints.x(:,end:-1:1);
    checkerPoints.y = checkerPoints.y(:,end:-1:1);
end
hError = zeros(size(checkerPoints.x,1),1);
for i = 1:size(checkerPoints.x,1)
    subI = arrayfun(@(j) [checkerPoints.x(i,j)+vw:checkerPoints.x(i,j+1)-vw;...
        round(interp1(checkerPoints.x(i,:),checkerPoints.y(i,:),checkerPoints.x(i,j)+vw:checkerPoints.x(i,j+1)-vw,'spline'))]...
        ,1:size(checkerPoints.x,2)-1,'UniformOutput',0);
    sIm = cellfun(@(indexes)subIm(ir,indexes(2,:),indexes(1,:),hw),subI,'UniformOutput',0);
    hError(i) = mean(cellfun(@(im)errorFunc(im),sIm));
end
hError = sqrt(mean(hError));
end

function err = errorFunc(ir)


irN=normByMax(ir);%normalize
irB=irN>graythresh(irN);%binarize
if(mean(vec(irB.*(linspace(-1,1,size(irB,1)))'))<0)
    irB=~irB;
end
irB=imclose(irB,ones(floor(size(irB,1)/4),1));%remove small gaps
zeroIfEmpty = @(x) iff(isempty(x),0,x);
c = arrayfun(@(i) zeroIfEmpty(find(irB(:,i),1)),1:size(irB));%find crossing
% err = var(c);
err = mean((c-(size(ir,1)-1)/2).^2);
err = err/2;%HD pixel

%
%
% HD_PIX_SIZE = 2;
% TH_FACTOR = 5;
% [minIr, maxIr] = minmax(ir);
% syImgNorm = (ir - minIr)/(maxIr - minIr);
% th = graythresh(syImgNorm);
% borderLine = ceil(size(syImgNorm,1)/2);
% if mean(vec(syImgNorm(1:borderLine-1,:))) > mean(vec(syImgNorm(borderLine+1:end,:))) %dark allways up
%     syImgNorm = syImgNorm(end:-1:1,:);
% end
%
% thIm = [syImgNorm(borderLine-1:-1:1,:) > th*(100 - TH_FACTOR)/100, syImgNorm(borderLine+1:end,:) < th*(100 + TH_FACTOR)/100];
% thIm = [thIm; zeros(1,size(thIm,2))];
% colDest = arrayfun(@(j)(find(thIm(:,j) == 0,1) - 1)*(2*(j>size(thIm,2)/2)-1),1:size(thIm,2));
% err = var(colDest) / HD_PIX_SIZE;
end

function sIm = subIm(im,i,j,w)
[~, y] = meshgrid(j,-w:w);
y = repmat(i,2*w+1,1) + y;
x = repmat(j,2*w+1,1);
sIm = reshape( im(sub2ind(size(im), y, x)),size(x));
end