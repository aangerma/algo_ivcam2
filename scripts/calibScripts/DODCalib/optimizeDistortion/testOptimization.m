% Get Current FW
fw = fw;
% Get Image
d = Calibration.aux.readAvgFrame(hw,30);
% Call function to Extract Checkerboard points in 2D.
p2D = getCBPoints2D(d);
% Call function to Extract Checkerboard points in 3D.
p3D = getCBPoints3D(d,regs);
% Create a function that calculates the distance matrix error from 3D.
% Also, obtain the gradients in respect to xyz locations.
[e,grads] = p3DtoError(p3D);
% create a function that calculates the gradient of the point in 3d in
% respect to x or y.

