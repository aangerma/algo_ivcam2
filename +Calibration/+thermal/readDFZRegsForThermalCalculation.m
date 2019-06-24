function currregs = readDFZRegsForThermalCalculation(hw,checkAssert,calibParams)
    
    currregs.EXTL.dsmXscale=typecast(hw.read('EXTLdsmXscale'),'single');
    currregs.EXTL.dsmYscale=typecast(hw.read('EXTLdsmYscale'),'single');
    currregs.EXTL.dsmXoffset=typecast(hw.read('EXTLdsmXoffset'),'single');
    currregs.EXTL.dsmYoffset=typecast(hw.read('EXTLdsmYoffset'),'single'); 

    DIGGspare = hw.read('DIGGspare');
    currregs.DIGG.spare = DIGGspare';
    currregs.FRMW.xfov(1) = typecast(DIGGspare(2),'single');
    currregs.FRMW.yfov(1) = typecast(DIGGspare(3),'single');
    currregs.FRMW.laserangleH = typecast(DIGGspare(4),'single');
    currregs.FRMW.laserangleV = typecast(DIGGspare(5),'single');
    currregs.DEST.txFRQpd = typecast(hw.read('DESTtxFRQpd'),'single')';

    DIGGspare06 = typecast(DIGGspare(7),'int32');
    DIGGspare07 = typecast(DIGGspare(8),'int32');
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
    currregs.GNRL.zMaxSubMMExp = hw.read('GNRLzMaxSubMMExp');

    JFILspare = hw.read('JFILspare');
    currregs.JFIL.spare = JFILspare';

    currregs.FRMW.dfzCalTmp = typecast(JFILspare(2),'single');
    currregs.FRMW.dfzApdCalTmp = typecast(JFILspare(7),'single');
    currregs.FRMW.pitchFixFactor = typecast(JFILspare(3),'single');
    currregs.FRMW.polyVars = typecast(JFILspare(4:6),'single');
    DCORspare = hw.read('DCORspare');
    currregs.DCOR.spare = DCORspare';
    currregs.FRMW.dfzVbias = typecast(DCORspare(3:5),'single');
    if checkAssert
        assert(all(currregs.FRMW.dfzVbias ~= 0),'dfzVbias from DCORspare are 0\n');
    end
    currregs.FRMW.dfzIbias = typecast(DCORspare(6:8),'single');
    
    currregs.DEST.p2axa = hex2single(dec2hex(hw.read('DESTp2axa')));
    currregs.DEST.p2axb = hex2single(dec2hex(hw.read('DESTp2axb')));
    currregs.DEST.p2aya = hex2single(dec2hex(hw.read('DESTp2aya')));
    currregs.DEST.p2ayb = hex2single(dec2hex(hw.read('DESTp2ayb')));
    
    JFILdnnWeights = hw.read('JFILdnnWeights');
    currregs.FRMW.undistAngVert = typecast(JFILdnnWeights(1:5),'single')';
    currregs.FRMW.undistAngHorz = typecast(JFILdnnWeights(6:10),'single')';

    
    currregs.DIGG.sphericalOffset	= typecast(hw.read('DIGGsphericalOffset'),'int16');
    currregs.DIGG.sphericalScale 	= typecast(hw.read('DIGGsphericalScale'),'int16');

    
    if calibParams.gnrl.sphericalMode
        currregs.DIGG.sphericalScale = int16(double(currregs.DIGG.sphericalScale).*calibParams.gnrl.sphericalScaleFactors);
        currregs.DEST.depthAsRange = 1; 
        currregs.DIGG.sphericalEn = 1;
        currregs.DEST.baseline = single(0);
        currregs.DEST.baseline2 = single(0);
    end
    
    currregs.FRMW.mirrorMovmentMode = 1;
    currregs.FRMW.projectionYshear = 0;
    currregs.MTLB.fastApprox = ones(1,8,'logical');
    
end

