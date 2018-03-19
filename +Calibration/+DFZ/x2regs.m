function rtlRegs = x2regs(x,rtlRegs)

switch(length(x))
    case 5
        iterRegs.FRMW.xfov=single(x(1));
        iterRegs.FRMW.yfov=single(x(2));
        iterRegs.DEST.txFRQpd=single([1 1 1]*x(3));
        iterRegs.FRMW.laserangleH=single(x(4));
        iterRegs.FRMW.laserangleV=single(x(5));
    case 3
        iterRegs.FRMW.xfov=single(x(1));
        iterRegs.FRMW.yfov=single(x(2));
        iterRegs.DEST.txFRQpd=single([1 1 1]*x(3));
    case 2
        iterRegs.FRMW.laserangleH=single(x(1));
        iterRegs.FRMW.laserangleV=single(x(2));
end
if(~exist('rtlRegs','var'))
    rtlRegs=iterRegs;
    return;
end

iterRegs.FRMW.xres=rtlRegs.GNRL.imgHsize;
iterRegs.FRMW.yres=rtlRegs.GNRL.imgVsize;
iterRegs.FRMW.marginL=int16(0);
iterRegs.FRMW.marginT=int16(0);

iterRegs.FRMW.xoffset=single(0);
iterRegs.FRMW.yoffset=single(0);
iterRegs.FRMW.undistXfovFactor=single(1);
iterRegs.FRMW.undistYfovFactor=single(1);
iterRegs.DIGG.undistBypass = false;
iterRegs.GNRL.rangeFinder=false;



rtlRegs =Firmware.mergeRegs( rtlRegs ,iterRegs);

trigoRegs = Pipe.DEST.FRMW.trigoCalcs(rtlRegs);
rtlRegs =Firmware.mergeRegs( rtlRegs ,trigoRegs);

diggRegs = Pipe.DIGG.FRMW.getAng2xyCoeffs(rtlRegs);
rtlRegs=Firmware.mergeRegs(rtlRegs,diggRegs);
end
