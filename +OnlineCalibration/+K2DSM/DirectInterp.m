function ySample = DirectInterp(xGrid, yGrid, xSample)
    % Designed for monotonically increasing xGrid
    
    ySample = zeros(size(xSample));
    xGridMin = min(xGrid);
    xGridMax = max(xGrid); 
    xSample(xSample<xGridMin) = xGridMin;
    xSample(xSample>xGridMax) = xGridMax;
    for ii = 1:length(xSample)
        ind = find(xGrid>=xSample(ii), 1, 'first');
        if (ind>1)
            ySample(ii) = (yGrid(ind-1)*(xGrid(ind)-xSample(ii))+yGrid(ind)*(xSample(ii)-xGrid(ind-1)))/(xGrid(ind)-xGrid(ind-1));
        else % xSample(ii)=xGrid(1)
            ySample(ii) = yGrid(1);
        end
    end
    
end
    
