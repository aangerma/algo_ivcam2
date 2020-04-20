function [xAlpha,yBeta,zGamma] = extractAnglesFromRotMat(R)
% [xAlpha,yBeta,zGamma] = OnlineCalibration.aux.rotationMatrixToEulerAngles(R);
% return;

epsilon = 0.00001;
xAlpha = atan2(-R(2,3),R(3,3));
yBeta = asin(R(1,3));
zGamma = atan2(-R(1,2),R(1,1));

if ~isExpressEqualToVal(xAlpha,yBeta,zGamma,R(2,1)) %xAlpha,yBeta,zGamma
    error('We got into this section! Please inform Tal');
    yBeta = yBeta+pi();
    if ~isExpressEqualToVal(xAlpha,yBeta,zGamma,R(2,1)) %xAlpha,yBeta+pi(),zGamma
        zGamma = zGamma+pi()./2;
        if ~isExpressEqualToVal(xAlpha,yBeta,zGamma,R(2,1)) %xAlpha,yBeta+pi(),zGamma+pi()/2
            yBeta = yBeta-pi();
            if ~isExpressEqualToVal(xAlpha,yBeta,zGamma,R(2,1))%xAlpha,yBeta,zGamma+pi()/2
                xAlpha = xAlpha + pi()./2;
                if ~isExpressEqualToVal(xAlpha,yBeta,zGamma,R(2,1))%xAlpha+pi()/2,yBeta,zGamma+pi()/2
                    yBeta = yBeta+pi();
                    if ~isExpressEqualToVal(xAlpha,yBeta,zGamma,R(2,1))%xAlpha+pi()/2,yBeta+pi(),zGamma+pi()/2
                        zGamma = zGamma-pi()./2;
                        if ~isExpressEqualToVal(xAlpha,yBeta,zGamma,R(2,1))%xAlpha+pi()/2,yBeta+pi(),zGamma
                            yBeta = yBeta-pi();
                            if ~isExpressEqualToVal(xAlpha,yBeta,zGamma,R(2,1))%xAlpha+pi()/2,yBeta,zGamma
                                error('No fit');
                            end
                        end
                    end
                end
            end
        end
    end
end
RwithAngs = [cos(yBeta).*cos(zGamma), -cos(yBeta).*sin(zGamma), sin(yBeta);...
    cos(xAlpha).*sin(zGamma) + cos(zGamma).*sin(xAlpha).*sin(yBeta), cos(xAlpha).*cos(zGamma) - sin(xAlpha).*sin(yBeta).*sin(zGamma), -cos(yBeta).*sin(xAlpha);...
    sin(xAlpha).*sin(zGamma) - cos(xAlpha).*cos(zGamma).*sin(yBeta), cos(zGamma).*sin(xAlpha) + cos(xAlpha).*sin(yBeta).*sin(zGamma),  cos(xAlpha).*cos(yBeta)];
if sum(sum(RwithAngs-R)) > epsilon
    error('No fit');
end
end

function [isEqual] = isExpressEqualToVal(xAlpha,yBeta,zGamma,val)
epsilon = 0.0001;
if cos(xAlpha)*sin(zGamma)+cos(zGamma)*sin(xAlpha)*sin(yBeta) > val+epsilon || cos(xAlpha)*sin(zGamma)+cos(zGamma)*sin(xAlpha)*sin(yBeta) < val-epsilon
    isEqual = false;
else
    isEqual = true;
end
end