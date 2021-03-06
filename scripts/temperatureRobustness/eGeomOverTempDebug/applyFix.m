function [fixedData] = applyFix(data,ref,fixes,regs)
fixedData = data;
for i = 1:numel(data.framesData)
    fdata = fixedData.framesData(i);
    
    %% LDD
    lddIndex = max(min(fdata.temp.ldd - 32,47),0)+1;
    
    if lddIndex == round(lddIndex)
        fdata.ptsWithZ(:,1) = fdata.ptsWithZ(:,1) + fixes.rtdTmptrOffsetValues(lddIndex);
    else
        lowVal = floor(lddIndex);
        highVal = ceil(lddIndex);
        fraq = lddIndex - lowVal;
        fdata.ptsWithZ(:,1) = fdata.ptsWithZ(:,1) + fixes.rtdTmptrOffsetValues(lowVal)*(1-fraq) + fixes.rtdTmptrOffsetValues(highVal)*(fraq);
    end
    
    
    %% AngY
    binIndex = ((fdata.vBias(2)-fixes.angy.minval)/((fixes.angy.maxval - fixes.angy.minval)/(fixes.angy.nBins)))+0.5;
    binIndex = max(min( binIndex ,48),1);
    if binIndex == round(binIndex)
        fdata.ptsWithZ(:,3) = fdata.ptsWithZ(:,3)*fixes.angy.scale(binIndex) + fixes.angy.offset(binIndex);
    else
        lowVal = floor(binIndex);
        highVal = ceil(binIndex);
        fraq = lddIndex - lowVal;
        scale = fixes.angy.scale(lowVal)*(1-fraq) + fixes.angy.scale(highVal)*(fraq);
        offset = fixes.angy.offset(lowVal)*(1-fraq) + fixes.angy.offset(highVal)*(fraq);
        
        
        fdata.ptsWithZ(:,3) = fdata.ptsWithZ(:,3) * scale + offset;
    end
    
    
    %% AngX
    dV1 = fixes.angx.p1(1) - fixes.angx.p0(1);
    dV3 = fixes.angx.p1(2) - fixes.angx.p0(2);
    binIndex = 0.5 + 47*(dV1*(fdata.vBias(1)- fixes.angx.p0(1)) + dV3*(fdata.vBias(3)- fixes.angx.p0(2)))/(dV1^2+dV3^2);
    binIndex = max(min( binIndex ,48),1);
    
    if binIndex == round(binIndex)
        fdata.ptsWithZ(:,3) = fdata.ptsWithZ(:,3)*fixes.angx.scale(binIndex) + fixes.angx.offset(binIndex);
    else
        lowVal = floor(binIndex);
        highVal = ceil(binIndex);
        fraq = lddIndex - lowVal;
        scale = fixes.angx.scale(lowVal)*(1-fraq) + fixes.angx.scale(highVal)*(fraq);
        offset = fixes.angx.offset(lowVal)*(1-fraq) + fixes.angx.offset(highVal)*(fraq);
        fdata.ptsWithZ(:,2) = fdata.ptsWithZ(:,2) * scale + offset;
    end
    
    
    
    
    fixedData.framesData(i) = fdata;
    
end

%% Update XYZ
for i = 1:numel(fixedData.framesData)
    [fixedData.framesData(i).ptsWithZ(:,2) ,fixedData.framesData(i).ptsWithZ(:,3)] = Calibration.Undist.applyPolyUndistAndPitchFix(fixedData.framesData(i).ptsWithZ(:,2) ,fixedData.framesData(i).ptsWithZ(:,3),regs);
    [fixedData.framesData(i).ptsWithZ(:,4) ,fixedData.framesData(i).ptsWithZ(:,5)] = Calibration.aux.ang2xySF(fixedData.framesData(i).ptsWithZ(:,2) ,fixedData.framesData(i).ptsWithZ(:,3),regs,[],1);
    fixedData.framesData(i).ptsWithZ(:,4) = fixedData.framesData(i).ptsWithZ(:,4) + 0.5;
    fixedData.framesData(i).ptsWithZ(:,5) = fixedData.framesData(i).ptsWithZ(:,5) + 0.5;
    
    [sinx,cosx,~,cosy,sinw,cosw,sing]=Pipe.DEST.getTrigo(fixedData.framesData(i).ptsWithZ(:,4)-0.5,fixedData.framesData(i).ptsWithZ(:,5)-0.5,regs);
    dnm = (fixedData.framesData(i).ptsWithZ(:,1) - regs.DEST.baseline.*sing);
    calcDenum = 1./ dnm;
    r= (0.5*(fixedData.framesData(i).ptsWithZ(:,1).^2 - regs.DEST.baseline2)).*calcDenum;
    z = r;
    coswx=cosw.*cosx;
    z = z.*coswx;
    x = r.*cosy.*sinx;
    y = r.*sinw;
    
    fixedData.framesData(i).ptsWithZ(:,6:8) = [x,y,z];
end
%% calc eGeom
for i = 1:numel(fixedData.framesData)
    [fixedData.framesData(i).eGeom, e2, e3,errors] = Validation.aux.gridError(fixedData.framesData(i).ptsWithZ(:,6:8), [9,13], 30);

end



end

