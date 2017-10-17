function [ jStream ] = gradient( jStream, regs, ~, instance, lgr,traceOutDir )

lgr.print2file('\t\t------- gradient -------\n');


if(~regs.JFIL.(sprintf('%sbypass',instance)))
    
    oImg = jStream.depth;
    oConf = jStream.conf;
    
    thrAveDx=sprintf('%sthrAveDx',instance);
    thrAveDy = sprintf('%sthrAveDy',instance);
    thrAveDiag = sprintf('%sthrAveDiag',instance);
    thrMinDx = sprintf('%sthrMinDx',instance);
    thrMinDy = sprintf('%sthrMinDy',instance);
    thrMinDiag = sprintf('%sthrMinDiag',instance);
    thrMaxDx = sprintf('%sthrMaxDx',instance);
    thrMaxDy = sprintf('%sthrMaxDy',instance);
    thrMaxDiag = sprintf('%sthrMaxDiag',instance);
    thrSpike = sprintf('%sthrSpike',instance);
    thrFactor = sprintf('%sThrFactor',instance);
    thrMode = sprintf('%sthrMode',instance);
    ConfLevel = sprintf('%sConfLevel',instance);
    Mask = sprintf('%sMask',instance);
    ConfUpdVal = sprintf('%sConfUpdVal',instance);
    %Invalidate = sprintf('%sInvalidate',instance);
    
    regsthrs = zeros([1 10], 'uint16');
    regsthrs(1) = regs.JFIL.(thrAveDx);
    regsthrs(2) = regs.JFIL.(thrAveDy);
    regsthrs(3) = regs.JFIL.(thrAveDiag);
    regsthrs(4) = regs.JFIL.(thrMinDx);
    regsthrs(5) = regs.JFIL.(thrMinDy);
    regsthrs(6) = regs.JFIL.(thrMinDiag);
    regsthrs(7) = regs.JFIL.(thrMaxDx);
    regsthrs(8) = regs.JFIL.(thrMaxDy);
    regsthrs(9) = regs.JFIL.(thrMaxDiag);
    regsthrs(10) = regs.JFIL.(thrSpike);
    
    LUT =uint32(regs.JFIL.(thrFactor));
    
    nPx = size(oImg,1)*size(oImg,2);
    
    ithr = repmat(regsthrs', [1 nPx]);
    iConf = repmat(oConf(:)', [10 1]);
    iDepth = repmat(oImg(:)', [10 1]);
    
    ithr = bitshift(ithr, regs.GNRL.zMaxSubMMExp);
    
    if regs.JFIL.(thrMode) == 0
        thresholds = ithr;
    elseif regs.JFIL.(thrMode) == 1
        thresholds = bitshift(uint32(ithr).*LUT((15-iConf)*4+1), -6);
    elseif regs.JFIL.(thrMode) == 2
        thresholds = bitshift(uint32(ithr).*LUT(bitshift(iDepth,-10)+1), -6);
    elseif regs.JFIL.(thrMode) == 3
        thresholds = bitshift(uint32(ithr)...
            .*LUT(bitshift(uint32(iDepth).*(15-uint32(iConf)),-14)+1), -6);
    end;
    
    thresholds = uint16(thresholds);
    
    validMask = uint8(oConf >= regs.JFIL.(ConfLevel));
    mask = uint16(regs.JFIL.(Mask));
    gradMask = Pipe.JFIL.grad(oImg,validMask, mask, thresholds);
    
    
    if regs.JFIL.(ConfUpdVal) ~= 0
        indZeros = (oConf == 0);
        oConf(gradMask==1) = regs.JFIL.(ConfUpdVal);
        oConf(indZeros) = 0;
    end;
    jStream.conf = oConf;
    

end
if (isfield(jStream,'debug'))
    jStream.debug{end+1}={instance,jStream.depth,jStream.ir,jStream.conf};
end


Pipe.JFIL.checkStreamValidity(jStream,instance,true);
if(~isempty(traceOutDir) )

    Utils.buildTracer([dec2hexFast(jStream.ir,3) dec2hexFast(jStream.conf,1) dec2hexFast(jStream.depth,4)],['JFIL_' instance],traceOutDir);
end

lgr.print2file('\t\t----- end gradient -----\n');

end

