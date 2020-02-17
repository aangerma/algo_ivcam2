function [verticalSharpnessRGB, horizontalSharpnessRGB] = fastGridEdgeSharpRGB(yuy2Im,gridSize,pts)
    

frame.yuy2 = yuy2Im;
ptsRGB = reshape(pts,[],2);
verticalSharpnessRGB = Calibration.aux.CBTools.fastGridEdgeSharpIR(frame, gridSize, ptsRGB , struct('target', struct('target', 'checkerboard_Iv2A1')),'yuy2');

ptsRGB = fliplr(ptsRGB);
ptsRGB = reshape(ptsRGB,20,28,2);
ptsRGB = reshape(permute(ptsRGB,[2,1,3]),[],2);
frame.yuy2 = yuy2Im';
gridSize = fliplr(gridSize);
horizontalSharpnessRGB = Calibration.aux.CBTools.fastGridEdgeSharpIR(frame, gridSize, ptsRGB , struct('target', struct('target', 'checkerboard_Iv2A1')),'yuy2');
