function yaw = getYawFromRotationMat(R)
% this function gets the rotation matrix and output the yaw, the rotation
% angle around the z axis. Calculates alpha from the equation in: http://planning.cs.uiuc.edu/node102.html
% Returns the angle up to sign
beta = asind(-R(3,1));
alpha = acosd(R(1,1)/cosd(beta));
yaw = alpha;
