clear
load('X:\Data\IvCam2\OnlineCalibration\Simulator\simulatedCB.mat');

sz = size(frame.z);
figure,imagesc(frame.z)
[gridHDX,gridHDY] = meshgrid(1:1920,1:1080);
[gridX,gridY] = meshgrid(1:sz(2),1:sz(1));
gridXT = (gridX-1)/(sz(2)-1)*(1920-1)+1;
gridYT = (gridY-1)/(sz(1)-1)*(1080-1)+1;
Zup = griddata(gridXT,gridYT,frame.z,gridHDX,gridHDY,'cubic');



[grX,grY] = meshgrid(1:sz(2),1:sz(1));


Zup = imresize(frame.z,[1080,1920],'bicubic');




lowTh = 6000;
[Ix,Iy] = imgradientxy(single(Zup));% Sobel image gradients [-1,0,1;-2,0,2;-1,0,1]
E = sqrt(Ix.^2+Iy.^2);
E(E<lowTh) = 0;
figure,imagesc(E)

direction = abs(atan2d(Iy,Ix));
[~,dirI] = min(abs(direction(:) - [0:45:135]),[],2);
dirsVec = [0,1; 1,1; 1,0; 1,-1];

supressedGrad = zeros(size(E));
for d = 1:size(dirsVec,1)
    currDir= dirsVec(d,:);
    maxGrad = (E >= circshift(circshift(E,currDir(1),1),currDir(2),2)) & (E >= circshift(circshift(E,-currDir(1),1),-currDir(2),2));
    maxGrad(dirI~=d) = 0;
    supressedGrad = supressedGrad+maxGrad;
end
supressedGrad(E < lowTh) = 0;
figure,imagesc(supressedGrad)

gradI = [gridHDX(:),gridHDY(:)];
gradI = gradI(supressedGrad(:)>0,:);
gradI = (gradI-1)./([1920,1080]-1).*(fliplr(sz)-1)+1;

figure,
imagesc(frame.z);
hold on
plot(gradI(:,1),gradI(:,2),'r*')
