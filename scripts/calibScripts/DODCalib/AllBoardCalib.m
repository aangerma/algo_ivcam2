% This is the idea:
% Find the DFZ from almost all board pixels instead of the corners. 
% Find all the pixels of the board. For each pixel get:
% pixelData(1,:) = [rtd, angx, angy, IR, xy Location in true board];
% Group pixels by their IR values. 
% The error will be the sum of the errors per IR Bin. 
% For each bin, the error will be the geometric pairwize distanse error. 


% Load the capture:
load('C:\git\ivcam2.0\scripts\calibScripts\DODCalib\DODCalibDataset\recordedData\regularCB_00.mat');
imagesc(d.i)
% Detect Corners
[p,bsz] = detectCheckerboardPoints(d.i);
bsz = bsz - 1;
pmat = reshape(p,[bsz,2]);

% Calculate

for i = 1:13
   x(i) =  pmat(1,i,1);
   y(i) =  pmat(1,i,2);
   
end

[cx,cy,c] = improfile(d.z,x,y),grid on; 
plot3(cx,cy,c)
for i = 1:13
   hold on;
   c(i) = improfile(d.z,pmat(1,i,1),pmat(1,i,2));
   plot3(pmat(1,i,1),pmat(1,i,2),c(i),'r*')
end

for i = 1:12
   dis(i) =  norm(squeeze(pmat(1,i,:)-pmat(1,i+1,:)));
end
plot(dis);

%% New idea:
% It is obvious that the reported angles are prone to errors. This is why
% we need distortion. however, until we fix the distortion, it seems that
% some of the corners are not located exactly were they should be. The
% displacement can be found by the undistort function. Let us found the bad
% corners and ignore them during the optimization of the DFZ.

[e,s,d] = Calibration.aux.evalProjectiveDisotrtion(d.i,0);