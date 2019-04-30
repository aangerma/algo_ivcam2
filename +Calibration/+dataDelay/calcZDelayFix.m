function [delaynsec,im]=calcZDelayFix(hw,imB)
%imD - top to bottom
%imU - bottom to top
%imB - both

[imU,imD]=Calibration.dataDelay.getScanDirImgs(hw);

delayPx = findCoarseDelay(imB, imU, imD);
% time per pixel in spherical coordinates
delaynsec = round(25*10^3*delayPx/size(imB,1)/2);

%time per pixel in spherical coordinates
%     nomMirroFreq = 20e3;
%     t=@(px)acos(-(px/size(im1,1)*2-1))/(2*pi*nomMirroFreq);


im=cat(3,imD,(imD+imU)/2,imU);


end


function delayInPx = findCoarseDelay(ir, alt1, alt2)

ir(isnan(ir)) = 0;
alt1(isnan(alt1)) = 0;
alt2(isnan(alt2)) = 0;


dir = diff(ir);
da1 = diff(alt1);
da2 = diff(alt2);

%% sigmoid kernel gradient
%{
kerLen = 3;
kerEdge = 1./(1+exp((-kerLen:kerLen)*1.5))-0.5;
%figure; plot(kerEdge)

dir = conv2(ir, kerEdge', 'valid');
da1 = conv2(a1, kerEdge', 'valid');
da2 = conv2(a2, kerEdge', 'valid');
%}

%% positive and negative gradients
% CRY = 100:380; % cropped range
% CRX = 50:500; % cropped range
% 
% dir_p = dir(CRY,CRX);
dir_p = dir;
dir_p(dir_p < 0) = 0;
% dir_n = dir(CRY,CRX);
dir_n = dir;
dir_n(dir_p > 0) = 0;


% da1_n = da1(CRY,CRX);
da1_n = da1;
da1_n(da1_n > 0) = 0;

% da2_p = da2(CRY,CRX);
da2_p = da2;
da2_p(da2_p < 0) = 0;


%% correlation

ns = 15; % search range

corr1 = conv2(dir_p, rot90(da2_p(ns+1:end-ns,:),2), 'valid');
corr2 = conv2(dir_n, rot90(da1_n(ns+1:end-ns,:),2), 'valid');
%figure; plot([corr1 flipud(corr2)]); title (sprintf('delay: %g', iFrame));

[~,iMax1] = max(corr1);
[~,iMax2] = max(corr2);

%delayInPx = iMax2 - iMax1;

peak1 = iMax1 + findPeak(corr1(iMax1-1), corr1(iMax1), corr1(iMax1+1));
peak2 = iMax2 + findPeak(corr2(iMax2-1), corr2(iMax2), corr2(iMax2+1));

delayInPx = (peak2 - peak1) / 2;




end

function peak = findPeak(i1, i2, i3)
d1 = i2 - i1;
d2 = i3 - i2;
peak = d1 / (d1 - d2) + 0.5;
end
