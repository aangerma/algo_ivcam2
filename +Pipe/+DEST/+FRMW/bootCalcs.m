function [regs,autogenRegs,autogenLuts] = bootCalcs(regs,luts,autogenRegs,autogenLuts)
N_TMPLT_BITS=3;
N_CMA_BITS = 6;
al1 = @(n) 2^n-1;

autogenRegs.DEST.fineCorrRange = uint16(16);

speedOfLightMMnsec = 299702547*1000/1e9;


%------------rx/txPWR LUT-----------------%

    if(regs.GNRL.rangeFinder)
        autogenRegs.DEST.txPWRpdLUTfactor = uint32(2^16/4);
    else
         autogenRegs.DEST.txPWRpdLUTfactor = uint32((2^16-1)*2^16/(double(regs.GNRL.imgVsize)-1));
    end
    rxLUTscale = 1;
    autogenRegs.DEST.rxPWRpdLUTfactor =uint32(2^16*(2^16-1)/(2^12-1)*rxLUTscale);
    
    %TODO: ROI (replace regs.GNRL.imgVsize with yres, truncate according to
    %margin)
    txAxis = single(linspace(0,double(regs.GNRL.imgVsize),65));
%     rxAxis = single(linspace(0,4096/rxLUTscale,65));

    stepFunc = @(x,th) th(1)*(.5-.5*erf((x-th(2))*th(3)));
     autogenRegs.DEST.txPWRpd =stepFunc(txAxis/double(regs.GNRL.imgVsize),regs.FRMW.destTxpdGen);
%     autogenRegs.DEST.rxPWRpd =stepFunc(rxAxis,regs.FRMW.destRxpdGen);
%    plot(rxAxis,autogenRegs.DEST.rxPWRpd)
    %interpolation
    autogenRegs.DEST.txPWRpd=autogenRegs.DEST.txPWRpd/2^10;
%     autogenRegs.DEST.rxPWRpd=autogenRegs.DEST.rxPWRpd/2^10;
    
%------------sampleDist-----------------%    
 % This should give us the length in mm per sample time, i.e.: the distance travled by light between two samples.
 hfClk = regs.FRMW.pllClock/4;
autogenRegs.DEST.sampleDist =[1 2 4]./single(regs.GNRL.sampleRate)*speedOfLightMMnsec/hfClk;
%------------baseline-----------------%    
autogenRegs.DEST.baseline2 = single(single(regs.DEST.baseline).^2);


C = double(regs.EXTL.corSaturationPrc);% of max to saturate to maximum

%------------ALT IR-----------------%
maxPeakVal=2^12-1;
autogenRegs.DEST.altIrDiv  = uint32(16*maxPeakVal*2^14/(C*al1(N_TMPLT_BITS)*al1(N_CMA_BITS)*double(regs.GNRL.tmplLength)));
autogenRegs.DEST.altIrSub  = uint32((al1(N_TMPLT_BITS)*al1(N_CMA_BITS)*double(regs.GNRL.tmplLength))/4);
%----------PEAK_VAL_NORM-----------
maxPeakVal = 2^6-1;
autogenRegs.DEST.maxvalDiv = uint32(4*maxPeakVal*2^14/(C*al1(N_TMPLT_BITS)*al1(N_CMA_BITS)*double(regs.GNRL.tmplLength)));
autogenRegs.DEST.maxvalSub = uint32(maxPeakVal/C);
%---------trigo funcs linear transofrmation------------------
trigoRegs = Pipe.DEST.FRMW.trigoCalcs(regs);
autogenRegs = Firmware.mergeRegs(autogenRegs,trigoRegs);
% xfovPix = regs.FRMW.xfov;
% yfovPix = regs.FRMW.yfov;
% if(regs.DIGG.undistBypass==0)
%     xfovPix = xfovPix*regs.FRMW.undistXfovFactor;
%     yfovPix = yfovPix*regs.FRMW.undistYfovFactor;
% end
% autogenRegs.DEST.p2axa = ( tand(xfovPix/2)* 2    / single(regs.FRMW.xres));
% autogenRegs.DEST.p2aya = ( tand(yfovPix/2)* 2    / single(regs.FRMW.yres));
% autogenRegs.DEST.p2axb = (-tand(xfovPix/2)*(1-2 *single(regs.FRMW.marginL) / single(regs.FRMW.xres) + single(regs.FRMW.xoffset) ));
% autogenRegs.DEST.p2ayb = (-tand(yfovPix/2)*(1-2 *single(regs.FRMW.marginT) / single(regs.FRMW.yres) + single(regs.FRMW.yoffset) ));
%------------ambiguityRTD------------------
autogenRegs.DEST.ambiguityRTD = single([1 2 4]*double(regs.GNRL.codeLength)*speedOfLightMMnsec);
autogenRegs.DEST.ambiguityRTD = autogenRegs.DEST.ambiguityRTD-single(1e-5);%????


regs = Firmware.mergeRegs(regs,autogenRegs);



end

