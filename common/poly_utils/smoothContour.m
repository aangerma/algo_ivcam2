% function [out_x,out_y] = smoothContour(in_x,in_y,smoothLength,maxSmoothLength2FullLengthRatio)
%
% Smoothes given polygon.
% Input:
% in_x,in_y - coordinates of polygon
% smoothLength - support of smoothing window
% maxSmoothLength2FullLengthRatio [default is 0.3] - if polygon is smaller in such a manner that the ratio of the window length 
% to the polygon length is smaller than this constant, then the window length is adjusted (i.e. becomes smaller) to fit.
function [out_x,out_y] = smoothContour(in_x,in_y,smoothLength,maxSmoothLength2FullLengthRatio)
out_x = [];
out_y = [];
if (~exist('maxSmoothLength2FullLengthRatio','var'))
        maxSmoothLength2FullLengthRatio = 0.3;
end;

smoothLength = double(smoothLength);
len = polylength(in_x,in_y);
N = int32(round(log2(len)));       
N = 2^N;
[in_x,in_y] = parametrizeContour(in_x,in_y,N);
ratio = smoothLength/len;
if (ratio > maxSmoothLength2FullLengthRatio)
        ratio = maxSmoothLength2FullLengthRatio;
end;
L = N * ratio;
if (L <= 1)
        return;
end;
if (mod(L,2)==0)
        L = L + 1;
end;

if (L > N)
         L = N;         % This is oversmoothing
end;

sqrSigma = L / 4;   
w = createNormalizedGaussWindow(L,sqrSigma);
out_x = in_x;
out_y = in_y;
for i=1:N
        sum_x = 0;
        sum_y = 0;
        for windowIndex = 0:L-1
                innerIndex = 1+mod((i+windowIndex),N);
                sum_x = sum_x + w(windowIndex+1)*in_x(innerIndex);
                sum_y = sum_y + w(windowIndex+1)*in_y(innerIndex);                        
        end;
        outerIndex = 1 + mod ( i-1+(L-1)/2 , N);
        out_x( outerIndex ) = sum_x;
        out_y( outerIndex ) = sum_y;
end;            % of outer for
out_x(end+1) = out_x(1);
out_y(end+1) = out_y(1);

end       % of main function


function w = createNormalizedGaussWindow(N,a)
N = double(N);
a = double(a);
k = -(N-1)/2:(N-1)/2;
w = exp((-1/2)*(a * k/(N/2)).^2)'; 
w = w / sum(w);
end

