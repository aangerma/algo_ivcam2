patgenregs.EPTG.maxZ = single(1000);
patgenregs.EPTG.zImageType = single(1);
patgenregs.EPTG.irImageType = single(1);
patgenregs.FRMW.xres=uint16(32);
patgenregs.FRMW.yres=uint16(32);
patgenregs.EPTG.slowscanType = uint8(3);
patgenregs.EPTG.noiseLevel=single(0);
patgenregs.EPTG.sampleJitter=single(0);
patgenregs.EPTG.frameRate=single(200);
patgenregs.JFIL.bypass=true;
patgenregs.EPTG.inputAsRange=true;
[ivsfn,gt]=Pipe.patternGenerator(patgenregs,tempdir);
pout=Pipe.autopipe(ivsfn);


