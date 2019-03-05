function fixTable = calcFixTable(transformationPerTemp,tmpBinEdges,regs)
fwTableSize = [92,5];
fwBinCenters = (25:0.5:70.5);
refTmpIndex = 1+floor((fwBinCenters-tmpBinEdges(1))/(tmpBinEdges(2)-tmpBinEdges(1)));
nonEmptyT = find(1-cellfun(@isempty,transformationPerTemp));
refTmpIndex = max(min(refTmpIndex,nonEmptyT(end)),nonEmptyT(1));


fixTable = zeros(fwTableSize);


for i = 1:fwTableSize(1)
    T = transformationPerTemp{refTmpIndex(i)};
    dsmXscale = T.angxA*regs.EXTL.dsmXscale;
    dsmXoffset = (regs.EXTL.dsmXoffset*dsmXscale-2048*T.angxA+T.angxB+2048)/dsmXscale;
    dsmYscale = T.angyA*regs.EXTL.dsmYscale;
    dsmYoffset = (regs.EXTL.dsmYoffset*dsmYscale-2048*T.angyA+T.angyB+2048)/dsmYscale;
    destTmprtOffset = T.rtdOffset;
    fixTable(i,:) = [dsmXscale,dsmYscale,dsmXoffset,dsmYoffset,destTmprtOffset];
    
end

end

