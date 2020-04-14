function Kworld = calcIntrinsicMat(calRegs, frameSize)
    % calcIntrinsicMat
    %   Calculates intrinsic matrix K for depth camera, for a specified frame size ([vertical resolution, horizontal resolution]), based on calibrated regs
    
    % Merging configuration with calibration
    fw = Firmware;
    defaultRegs = fw.get();
    regs = fw.mergeRegs(defaultRegs, calRegs);
    
    % Applying specified frame size
    regs.GNRL.imgHsize = frameSize(2);
    regs.GNRL.imgVsize = frameSize(1);
    
    % Starting autogen
    [autogenRegs, regs] = Pipe.DIGG.FRMW.calculateMargins(regs, struct);
    t = Pipe.DIGG.FRMW.getAng2xyCoeffs(regs);
    autogenRegs = fw.mergeRegs(autogenRegs, t);
    regs = fw.mergeRegs(regs, autogenRegs);
    regsOut = Pipe.DEST.FRMW.trigoCalcs(regs);
    
    % Intrinsic matrix calculation
    KinvRaw = [regsOut.DEST.p2axa,    0,                      regsOut.DEST.p2axb;
               0,                     regsOut.DEST.p2aya,     regsOut.DEST.p2ayb;
               0,                     0,                      1];
    KRaw = inv(KinvRaw);
    KRaw = abs(KRaw);
    
    Kworld = KRaw;
    Kworld(1,3) = single(frameSize(2))-1-KRaw(1,3);
    Kworld(2,3) = single(frameSize(1))-1-KRaw(2,3);

end