function [R] = calcRmatRromAngs(xAlpha,yBeta,zGamma)
R = [cos(yBeta)*cos(zGamma), -cos(yBeta)*sin(zGamma), sin(yBeta);...
    cos(xAlpha)*sin(zGamma) + cos(zGamma)*sin(xAlpha)*sin(yBeta), cos(xAlpha)*cos(zGamma) - sin(xAlpha)*sin(yBeta)*sin(zGamma), -cos(yBeta)*sin(xAlpha);...
    sin(xAlpha)*sin(zGamma) - cos(xAlpha)*cos(zGamma)*sin(yBeta), cos(zGamma)*sin(xAlpha) + cos(xAlpha)*sin(yBeta)*sin(zGamma),  cos(xAlpha)*cos(yBeta)];

end

