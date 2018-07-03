function [p,og] =getTargetParams(targetType)
    if(~exist('targetType','var'))
        targetType=1;
    end
    
    switch(targetType)
        case 1
            p.cornersX=13;
            p.cornersY=9;
            p.mmPerUnitY=30;
            p.mmPerUnitX=30;
        otherwise
            error('unknonw target type');
    end
    [oy,ox]=ndgrid(linspace(-1,1,p.cornersY)*(p.cornersY-1)*p.mmPerUnitY/2,linspace(-1,1,p.cornersX)*(p.cornersX-1)*p.mmPerUnitY/2);
    og = [ox(:) oy(:) zeros(numel(ox),1)]';
    
end