%IRs = {}; i = 1;
%IRs{i} = hw.getFrame(30); figure; imagesc(IRs{i}.i); i = i + 1;
% K=reshape([typecast(hw.read('CBUFspare'),'single');1],3,3)';

load('checkerboard_0626.mat');

boardSize = [7 7];
nImages = length(IRs);
imagePoints = zeros(boardSize(1)*boardSize(2), 2, nImages);


%% detect checker board
for i=1:nImages
    %ir = fliplr(IRs{i}.i);
    ir = (IRs{i}.i);
    figure(77); imagesc(ir); hold on;
    [gridPoints, gridSize]=findCheckerboard(ir, boardSize);
    if (~isequal(gridSize, boardSize))
        warning(sprintf('Grid not found in image %g', i));
    end
    imagePoints(:,:,i) = gridPoints;
    
    plot(gridPoints(:,1), gridPoints(:,2), '+r'); hold off;
end

%% compute world coordinates
squareSize = 50;
worldPoints = generateCheckerboardPoints(boardSize+1, squareSize);

% Calibrate the camera.
imageSize = [size(IRs{i}.i, 1), size(IRs{i}.i, 2)];
[params, ~, estimationErrors] = estimateCameraParameters(imagePoints, worldPoints, ...
    'ImageSize', imageSize);

figure; showReprojectionErrors(params);
figure; showExtrinsics(params);

%% estimate errors
errors = zeros(nImages,4);
for i=1:nImages
    gridPoints = imagePoints(:,:,i);
    vP = toVertices(gridPoints, (IRs{i}.z), K);
    vM = toVertices(gridPoints, (IRs{i}.z), params.IntrinsicMatrix');
    [errors(i,1), errors(i,2)] = gridError(vP, squareSize);
    [errors(i,3), errors(i,4)] = gridError(vM, squareSize);
end

figure; plot(errors); legend('L1 K', 'L2 K', 'L1 Matlab', 'L2 Matlab');

%% K computation

xfov = 67.7611;
yfov = 54.4618;
xres = 682;
yres = 519;


marginL = 5;
marginR = 37;
marginT = 20;
marginB = 19;

p2axa = ( tand(xfov/2)* 2    / single(xres-1));
p2axb = (-tand(xfov/2)*(1 - 2*single(marginL) / single(xres) ));
p2aya = ( tand(yfov/2)*2    / single(yres-1));
p2ayb = (-tand(yfov/2)*(1 - 2*single(marginT) / single(yres) ));
[p2axa,p2axb,p2aya,p2ayb] = rangeCalc(regs);
K33=[p2axa 0 p2axb;
   0 p2aya p2ayb;
   0 0 1];

K33inv=pinv(K33);
