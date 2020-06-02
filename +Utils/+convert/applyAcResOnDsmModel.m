function dsmRegsOut = applyAcResOnDsmModel(acData, dsmRegsIn, type)
    
    switch type
        case 'direct' % convert from original model to modified model
            switch acData.flags(1)
                case 0 % none
                    dsmRegsOut = dsmRegsIn;
                case 1 % AOT model
                    dsmRegsOut.dsmXscale = double(dsmRegsIn.dsmXscale) * double(acData.hFactor);
                    dsmRegsOut.dsmYscale = double(dsmRegsIn.dsmYscale) * double(acData.vFactor);
                    dsmRegsOut.dsmXoffset = (double(dsmRegsIn.dsmXoffset) + double(acData.hOffset)) / double(acData.hFactor);
                    dsmRegsOut.dsmYoffset = (double(dsmRegsIn.dsmYoffset) + double(acData.vOffset)) / double(acData.vFactor);
                case 2 % TOA model
                    dsmRegsOut.dsmXscale = double(dsmRegsIn.dsmXscale) * double(acData.hFactor);
                    dsmRegsOut.dsmYscale = double(dsmRegsIn.dsmYscale) * double(acData.vFactor);
                    dsmRegsOut.dsmXoffset = double(dsmRegsIn.dsmXoffset) + double(acData.hOffset) / double(dsmRegsIn.dsmXscale);
                    dsmRegsOut.dsmYoffset = double(dsmRegsIn.dsmYoffset) + double(acData.vOffset) / double(dsmRegsIn.dsmYscale);
                otherwise
                    error('Only {0,1,2} are supported as values for "flags"');
            end
        case 'inverse' % revert from modified model to original model
            switch acData.flags(1)
                case 0 % none
                    dsmRegsOut = dsmRegsIn;
                case 1 % AOT model
                    dsmRegsOut.dsmXscale = double(dsmRegsIn.dsmXscale) / double(acData.hFactor);
                    dsmRegsOut.dsmYscale = double(dsmRegsIn.dsmYscale) / double(acData.vFactor);
                    dsmRegsOut.dsmXoffset = double(dsmRegsIn.dsmXoffset) * double(acData.hFactor) - double(acData.hOffset);
                    dsmRegsOut.dsmYoffset = double(dsmRegsIn.dsmYoffset) * double(acData.vFactor) - double(acData.vOffset);
                case 2 % TOA model
                    dsmRegsOut.dsmXscale = double(dsmRegsIn.dsmXscale) / double(acData.hFactor);
                    dsmRegsOut.dsmYscale = double(dsmRegsIn.dsmYscale) / double(acData.vFactor);
                    dsmRegsOut.dsmXoffset = double(dsmRegsIn.dsmXoffset) - double(acData.hOffset) / double(dsmRegsOut.dsmXscale);
                    dsmRegsOut.dsmYoffset = double(dsmRegsIn.dsmYoffset) - double(acData.vOffset) / double(dsmRegsOut.dsmYscale);
                otherwise
                    error('Only {0,1,2} are supported as values for "flags"');
            end
    end
    
end

