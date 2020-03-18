function [xOut, yOut] = applyDsm(xIn, yIn, params, type)
    switch type
        case 'direct' % convert from degrees to digital units
            xOut = (xIn + double(params.dsmXoffset)) * double(params.dsmXscale) - 2047;
            yOut = (yIn + double(params.dsmYoffset)) * double(params.dsmYscale) - 2047;
        case 'inverse' % convert from digital units to degrees
            xOut = (xIn + 2047)/double(params.dsmXscale) - double(params.dsmXoffset);
            yOut = (yIn + 2047)/double(params.dsmYscale) - double(params.dsmYoffset);
    end
end