% K=reshape([typecast(hw.read('CBUFspare'),'single');1],3,3)';

load('checkerboard_ivcam2.mat');

boardSize = [7 7];
nImages = length(IRs);
imagePoints = zeros(boardSize(1)*boardSize(2), 2, nImages);


%% detect checker board
for i=1:nImages
    ir = fliplr(IRs{i}.i);
    [gridPoints, gridSize]=findCheckerboard(ir, boardSize);
    if (~isequal(gridSize, boardSize))
        warning(sprintf('Grid not found in image %g', i));
    end
    imagePoints(:,:,i) = gridPoints;
    
    figure(77); imagesc(ir); hold on; plot(gridPoints(:,1), gridPoints(:,2), '+r'); hold off;
end

%% compute world coordinates
squareSize = 50;
worldPoints = generateCheckerboardPoints(boardSize+1, squareSize);

% Calibrate the camera.
imageSize = [size(IRs{i}.i, 1), size(IRs{i}.i, 2)];
[params, ~, estimationErrors] = estimateCameraParameters(imagePoints, worldPoints, ...
    'ImageSize', imageSize);

showReprojectionErrors(params);
                                 
%% K computation

xfov = 72;
yfov = 52;
xres = 640;
yres = 480;
marginL = 0;
marginT = 0;
xoffset = 0;
yoffset = 0;

p2axa = ( tand(xfov/2)* 2    / single(xres-1));
p2axb = (-tand(xfov/2)*(1 - 2*single(marginL) / single(xres) + single(xoffset)));
p2aya = ( tand(yfov/2)*2    / single(yres-1));
p2ayb = (-tand(yfov/2)*(1 - 2*single(marginT) / single(yres) + single(yoffset)));

K=[p2axa 0 p2axb;
   0 p2aya p2ayb;
   0 0 1];

Kinv=pinv(K);
