function [t, xLims, yLims] = genMapSphericalPixel2Time(im, fResMirror)
    % t = genMapSphericalPixel2Time(im)
    %   Generates mapping of spherical pixels to relative time within scan
    % input:
    %   im - IR image (taken in spherical mode)
    %   fResMirror - mirror resonance frequency measured in unit [Hz]
    % output:
    %   t - time within scan [sec] (function handle)
    %   xLims - left/right borders of primary visited region (array of scalars)
    %   yLims - upper/bottom borders of primary visited region (cell array of function handles)

    % finding borders of primary visited region
    [nPixY, nPixX] = size(im);
    minPixX = 1 + find(im(nPixY/2, 1:nPixX/2)==0, 1, 'last'); % left border
    if isempty(minPixX)
        minPixX = 1;
    end
    maxPixX = (nPixX/2 - 1) + find(im(nPixY/2, nPixX/2:end)==0, 1, 'first') - 1; % right border
    if isempty(maxPixX)
        maxPixX = nPixX;
    end
    xLims = [minPixX, maxPixX];
    xPixels = minPixX:maxPixX;
    minVisitedPixY = NaN(1,length(xPixels)); % upper border
    maxVisitedPixY = NaN(1,length(xPixels)); % bottom border
    for k = 1:length(xPixels)
        validPixels = find(im(:, xPixels(k))>0);
        if ~isempty(validPixels)
            minVisitedPixY(k) = validPixels(1);
            maxVisitedPixY(k) = validPixels(end);
        end
    end
    
    % smoothing upper & bottom borders
    xFactor = 0.75; % to avoid abnormality in upper-right part of the primary visited region
    xi = xPixels(1:round(xFactor*length(xPixels)));
    yi = minVisitedPixY(1:round(xFactor*length(xPixels)));
    pMin = polyfit(xi(~isnan(yi)), yi(~isnan(yi)), 1);
    yMin = @(xx) pMin(1)*xx + pMin(2);
    xi = xPixels;
    yi = maxVisitedPixY;
    pMax = polyfit(xi(~isnan(yi)), yi(~isnan(yi)), 1);
    yMax = @(xx) pMax(1)*xx + pMax(2);
    yLims = {yMin, yMax};
    
    % mapping pixel to relative time within scan
    t = @(x,y) acos(-( (y-yMin(x))./(yMax(x)-yMin(x)) * 2 - 1) ) / (2*pi*fResMirror);
end