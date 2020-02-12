clear
load('X:\Data\IvCam2\OnlineCalibration\Simulator\simulatedCB.mat');

sz = size(frame.z);
[gridX,gridY] = meshgrid(1:sz(2),1:sz(1));

Zup = frame.z;

lowTh = 4*300;
[Ix,Iy] = imgradientxy(single(Zup));% Sobel image gradients [-1,0,1;-2,0,2;-1,0,1]
E = sqrt(Ix.^2+Iy.^2);
E(E<lowTh) = 0;
figure,imagesc(E)

direction = abs(atan2d(Iy,Ix));
[~,dirI] = min(abs(direction(:) - [0:45:135]),[],2);
dirsVec = [0,1; 1,1; 1,0; 1,-1];

subPixelGrads = [];
supressedGrad = zeros(size(E));
for d = 1:size(dirsVec,1)
    currDir= dirsVec(d,:);
    E_plus = circshift(E,-currDir);
    E_minus = circshift(E,+currDir);
    E_edge = (E >= E_plus) & (E >= E_minus) & (E>lowTh);
    % Fit parab, take max:    
%     maxGrad = (E >= circshift(circshift(E,currDir(1),1),currDir(2),2)) & (E >= circshift(circshift(E,-currDir(1),1),-currDir(2),2));
%     maxGrad(dirI~=d) = 0;
    
    subGrad = vec(-0.5*(E_plus-E_minus)./(E_plus+E_minus-2*E)).*currDir;
    subGrad = subGrad + [gridY(:),gridX(:)];
    subGrad = subGrad(E_edge(:)>0  & dirI==d,:);
    subPixelGrads = [subPixelGrads;subGrad]; 
    
%     supressedGrad = supressedGrad+maxGrad;

end
% 
% supressedGrad(E < lowTh) = 0;
% figure,imagesc(supressedGrad)
figure,imagesc(frame.z)
hold on
plot(subPixelGrads(:,2),subPixelGrads(:,1),'*r')


% gradI = [gridHDX(:),gridHDY(:)];
% gradI = gradI(supressedGrad(:)>0,:);
% gradI = (gradI-1)./([1920,1080]-1).*(fliplr(sz)-1)+1;

% figure,
% imagesc(frame.z);
% hold on
% plot(gradI(:,1),gradI(:,2),'r*')
