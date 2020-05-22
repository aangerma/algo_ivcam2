function dsmRegsOut = applyAcResOnDsmModel(acData, dsmRegsIn, type)
   dsmRegsOut = dsmRegsIn;
    switch type
        case 'direct' % convert from original model to modified model
            switch acData.flags(1)
                case 0 % none
                    dsmRegsOut = dsmRegsIn;
                case 1 % AOT model
                    dsmRegsOut.dsmXscale = dsmRegsIn.dsmXscale * acData.hFactor;
                    dsmRegsOut.dsmYscale = dsmRegsIn.dsmYscale * acData.vFactor;
                    dsmRegsOut.dsmXoffset = (dsmRegsIn.dsmXoffset + acData.hOffset) / acData.hFactor;
                    dsmRegsOut.dsmYoffset = (dsmRegsIn.dsmYoffset + acData.vOffset) / acData.vFactor;
                case 2 % TOA model
                    dsmRegsOut.dsmXscale = dsmRegsIn.dsmXscale * acData.hFactor;
                    dsmRegsOut.dsmYscale = dsmRegsIn.dsmYscale * acData.vFactor;
                    dsmRegsOut.dsmXoffset = dsmRegsIn.dsmXoffset + acData.hOffset / dsmRegsIn.dsmXscale;
                    dsmRegsOut.dsmYoffset = dsmRegsIn.dsmYoffset + acData.vOffset / dsmRegsIn.dsmYscale;
                otherwise
                    error('Only {0,1,2} are supported as values for "flags"');
            end
        case 'inverse' % revert from modified model to original model
            switch acData.flags(1)
                case 0 % none
                    dsmRegsOut = dsmRegsIn;
                case 1 % AOT model
                    dsmRegsOut.dsmXscale = dsmRegsIn.dsmXscale / acData.hFactor;
                    dsmRegsOut.dsmYscale = dsmRegsIn.dsmYscale / acData.vFactor;
                    dsmRegsOut.dsmXoffset = dsmRegsIn.dsmXoffset * acData.hFactor - acData.hOffset;
                    dsmRegsOut.dsmYoffset = dsmRegsIn.dsmYoffset * acData.vFactor - acData.vOffset;
                case 2 % TOA model
                    dsmRegsOut.dsmXscale = dsmRegsIn.dsmXscale / acData.hFactor;
                    dsmRegsOut.dsmYscale = dsmRegsIn.dsmYscale / acData.vFactor;
                    dsmRegsOut.dsmXoffset = dsmRegsIn.dsmXoffset - acData.hOffset / dsmRegsOut.dsmXscale;
                    dsmRegsOut.dsmYoffset = dsmRegsIn.dsmYoffset - acData.vOffset / dsmRegsOut.dsmYscale;
                otherwise
                    error('Only {0,1,2} are supported as values for "flags"');
                    
            end
    end
    
end