function [ Inorm,Ilow,Ihigh ] = normalizedImage( I )
% normalize image fixes vignetting by:
% 1. Detecting points that should by white/black.
% 2. fit a 2D polinomial function to the black and white points. The
% resulting maps are called Ihigh and Ilow. 
% 3. It calculates the normalized image by: Inorm = (I-Ilow)/(Ihigh-Ilow)

[ ~,blackCorners, ~, ~,whiteCorners,whiteCenters ] = Calibration.aux.CBTools.getCBSquares( I );

 
% For each point, get the corresponding value from the image. Use 5x5
% median filtering to reduce the chance we sample a specific point 
% which is very noisy.
whitePoints = [whiteCorners;whiteCenters];
blackPoints = blackCorners;
allPoints = [whitePoints;blackPoints];

Imed = medfilt2(I,[5 5]);
trueValues = interp2(1:size(I,2),1:size(I,1),single(Imed),allPoints(:,1),allPoints(:,2));




%% Fit a 4th order polinomial to the black and white squares. subtract them from the image and normalize by the difference.
polOrd = 4;
coeffsWhite = fit2Dpoli(whitePoints(:,1),whitePoints(:,2),trueValues(1:size(whitePoints,1)),polOrd);
coeffsBlack = fit2Dpoli(blackPoints(:,1),blackPoints(:,2),trueValues(size(whitePoints,1)+1:end),polOrd);
% High mesh:

[gy,gx] = ndgrid(1:size(I,1),1:size(I,2) );
Ihigh = reshape(apply2Dpoli(gx(:),gy(:),polOrd,coeffsWhite),size(gy));
Ilow = reshape(apply2Dpoli(gx(:),gy(:),polOrd,coeffsBlack),size(gy));
Inorm = (I-Ilow)./(Ihigh-Ilow);
% if verbose
%     figure(190793)
%     tabplot;
%     imagesc(I);
%     tabplot;
%     imagesc(Ihigh),title('I high');
%     tabplot;
%     imagesc(Ilow),title('I low');
% 
%     % Normalize the image:
%     tabplot;
%     imagesc(Inorm),title('I normalized');
% end



end

