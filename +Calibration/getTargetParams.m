function p =getTargetParams(targetType)
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
    
    
end