function currregs = readDFZRegsForThermalCalculation(hw)
    
    currregs.EXTL.dsmXscale=typecast(hw.read('EXTLdsmXscale'),'single');
    currregs.EXTL.dsmYscale=typecast(hw.read('EXTLdsmYscale'),'single');
    currregs.EXTL.dsmXoffset=typecast(hw.read('EXTLdsmXoffset'),'single');
    currregs.EXTL.dsmYoffset=typecast(hw.read('EXTLdsmYoffset'),'single'); 

    DIGGspare = hw.read('DIGGspare');
    currregs.FRMW.xfov(1) = typecast(DIGGspare(2),'single');
    currregs.FRMW.yfov(1) = typecast(DIGGspare(3),'single');
    currregs.FRMW.laserangleH = typecast(DIGGspare(4),'single');
    currregs.FRMW.laserangleV = typecast(DIGGspare(5),'single');
    currregs.DEST.txFRQpd = typecast(hw.read('DESTtxFRQpd'),'single')';

    DIGGspare06 = typecast(hw.read('DIGGspare_006'),'int32');
    DIGGspare07 = typecast(hw.read('DIGGspare_007'),'int32');
    currregs.FRMW.calMarginL = typecast(uint16(bitshift(DIGGspare06,-16)),'int16');
    currregs.FRMW.calMarginR = typecast(uint16(mod(DIGGspare06,2^16)),'int16');
    currregs.FRMW.calMarginT = typecast(uint16(bitshift(DIGGspare07,-16)),'int16');
    currregs.FRMW.calMarginB = typecast(uint16(mod(DIGGspare07,2^16)),'int16');
    
    currregs.GNRL.imgHsize = hw.read('GNRLimgHsize');
    currregs.GNRL.imgVsize = hw.read('GNRLimgVsize');

    currregs.DEST.baseline = typecast(hw.read('DESTbaseline$'),'single');
    currregs.DEST.baseline2 = typecast(hw.read('DESTbaseline2'),'single');
    currregs.DEST.hbaseline = hw.read('DESThbaseline');
    
    currregs.FRMW.kWorld = hw.getIntrinsics();
    currregs.FRMW.kRaw = currregs.FRMW.kWorld;
    currregs.FRMW.kRaw(7) = single(currregs.GNRL.imgHsize) - 1 - currregs.FRMW.kRaw(7);
    currregs.FRMW.kRaw(8) = single(currregs.GNRL.imgVsize) - 1 - currregs.FRMW.kRaw(8);
    currregs.GNRL.zNorm = hw.z2mm;
    
    JFILspare = hw.read('JFILspare');
    currregs.FRMW.dfzCalTmp = typecast(JFILspare(2),'single');
end

