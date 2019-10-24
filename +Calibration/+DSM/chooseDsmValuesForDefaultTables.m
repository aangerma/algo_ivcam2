close all
clear all
clc

% extreme values - according to 324 coarse DSM calibs during 23.6-23.10.19
angyMin = -29.14; % [deg]
angyMax = 28.41; % [deg]
angxMin = -31.99; % [deg]
angxMax = 32.47; % [deg]

marginDeg = 1; % [deg]
fullDynRangeY = (angyMax+marginDeg) - (angyMin-marginDeg);
fullDynRangeX = (angxMax+marginDeg) - (angxMin-marginDeg);

yScale = single(4095/fullDynRangeY);
yOffset = single(4095/yScale - angyMax);
xScale = single(4095/fullDynRangeX);
xOffset = single(4095/xScale - angxMax);


