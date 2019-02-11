function [regs,autogenRegs,autogenLuts] = fwBootCalcs(regs,luts,autogenRegs,autogenLuts)
%% ======================= constants====================
N_TMPLT_BITS=3;
N_CMA_BITS = 6;
speedOfLightMMnsec = 299702547*1000/1e9;
autogenRegs.DEST.fineCorrRange = uint16(16);
regs = Firmware.mergeRegs(regs,autogenRegs);

%% =======================================rx/txPWR LUT =======================================
% rx_txFactors function calculates LUTS factors for tx and rx RPD.
% The calculations produces:DEST.txPWRpdLUTfactor, DEST.rxPWRpdLUTfactor
% rx_txFactors function should be calculated when one of the following is changing:
%  Regs from external configuration:regs.GNRL.rangeFinder,regs.GNRL.imgVsize

[regs,autogenRegs] = rx_txFactors(regs,autogenRegs);

%% %------------sampleDist-----------------%
% calculateSampleDist function gives us the length in mm per sample time, i.e.: the distance travled by light between two samples.
% The calculations produces:DEST.sampleDist
% calculateSampleDist function should be calculated when one of the following is changing:
%  Regs from external configuration:regs.GNRL.sampleRate, regs.FRMW.pllClock

[regs,autogenRegs] = calculateSampleDist(regs,autogenRegs,speedOfLightMMnsec);


%% %------------baseline-----------------%
% The calculations produces:DEST.baseline2
% this function should be calculated when the camera is initialized:
%  Regs from EPROM: regs.DEST.baseline

autogenRegs.DEST.baseline2 = single(single(regs.DEST.baseline).^2);
regs = Firmware.mergeRegs(regs,autogenRegs);
%% % DEST.decRatio             %   ratio between coarse and fine in DEST block
autogenRegs.DEST.decRatio = regs.DCOR.decRatio;
regs = Firmware.mergeRegs(regs,autogenRegs);

%% %------------ALT IR & PEAK_VAL_NORM-----------------%
% altIR_peakVal function calculates parameters for alternate IR image base
% on the peak correlation values. and also calculates max val params for
% confidence level calculation. 
% altIR_peakVal function should be calculated when one of the following is changing:
%  Regs from external configuration:regs.FRMW.corSaturationPrc, regs.GNRL.tmplLength

[regs,autogenRegs] = altIR_peakVal(regs,autogenRegs,N_TMPLT_BITS,N_CMA_BITS);

%% %---------trigo funcs linear transofrmation------------------
% calculateIntrinsic function calculates camera intrinsic
% The calculations produces:DEST.p2axa,DEST.p2axb,DEST.p2aya,DEST.p2ayb,FRMW.kRaw, FRMW.kWorld,FRMW.zoRaw,FRMW.zoWorld
% calculateIntrinsic function should be calculated when one of the following is changing:
% regs from previous bootcalc: regs.FRMW.xres,regs.FRMW.yres
%  Regs from external configuration:regs.FRMW.mirrorMovmentMode,regs.DIGG.undistBypass,regs.FRMW.undistXfovFactor,regs.FRMW.undistYfovFactor,regs.GNRL.imgHsize,regs.GNRL.imgVsize
%  Regs from EPROM: regs.FRMW.laserangleH,regs.FRMW.laserangleV,regs.FRMW.projectionYshear,regs.FRMW.xfov, regs.FRMW.yfov, regs.FRMW.marginL/R/T/B,

[regs,autogenRegs]=calculateIntrinsic(regs,autogenRegs); 


%% -------ambiguity-----------------
% The calculations produces Ambiguity RTD
% this function should be calculated when one of the following is changing:
%  Regs from external: regs.GNRL.codeLength

[regs,autogenRegs] = calculateAmbiguityRTD(regs,autogenRegs,speedOfLightMMnsec); 

end



function [regs,autogenRegs] = rx_txFactors(regs,autogenRegs)
if(regs.GNRL.rangeFinder)
    autogenRegs.DEST.txPWRpdLUTfactor = uint32(2^16/4);
else
    autogenRegs.DEST.txPWRpdLUTfactor = uint32((2^16-1)*2^16/(double(regs.GNRL.imgVsize)-1));
end

autogenRegs.DEST.rxPWRpdLUTfactor =uint32(2^16*(2^16-1)/(2^12-1));
regs = Firmware.mergeRegs(regs,autogenRegs);

end

function [regs,autogenRegs] = calculateSampleDist(regs,autogenRegs,speedOfLightMMnsec)
hfClk = regs.FRMW.pllClock/4;
autogenRegs.DEST.sampleDist =[1 2 4]./single(regs.GNRL.sampleRate)*speedOfLightMMnsec/hfClk;
regs = Firmware.mergeRegs(regs,autogenRegs);
end

function [regs,autogenRegs] = altIR_peakVal(regs,autogenRegs,N_TMPLT_BITS,N_CMA_BITS)
al1 = @(n) 2^n-1;

C = double(regs.FRMW.corSaturationPrc);% of max to saturate to maximum

%------------ALT IR-----------------%
maxPeakVal=2^12-1;
autogenRegs.DEST.altIrDiv  = uint32(16*maxPeakVal*2^14/(C*al1(N_TMPLT_BITS)*al1(N_CMA_BITS)*double(regs.GNRL.tmplLength)));
autogenRegs.DEST.altIrSub  = uint32((al1(N_TMPLT_BITS)*al1(N_CMA_BITS)*double(regs.GNRL.tmplLength))/4);
%----------PEAK_VAL_NORM-----------
maxPeakVal = 2^6-1;
autogenRegs.DEST.maxvalDiv = uint32(4*maxPeakVal*2^14/(C*al1(N_TMPLT_BITS)*al1(N_CMA_BITS)*double(regs.GNRL.tmplLength)));
autogenRegs.DEST.maxvalSub = uint32(maxPeakVal/C);
regs = Firmware.mergeRegs(regs,autogenRegs);

end 


function [regs,autogenRegs]=calculateIntrinsic(regs,autogenRegs)
trigoRegs = Pipe.DEST.FRMW.trigoCalcs(regs);
autogenRegs = Firmware.mergeRegs(autogenRegs,trigoRegs);
regs = Firmware.mergeRegs(regs,autogenRegs);

end 
function [regs,autogenRegs] = calculateAmbiguityRTD(regs,autogenRegs,speedOfLightMMnsec)
autogenRegs.DEST.ambiguityRTD = single([1 2 4]*double(regs.GNRL.codeLength)*speedOfLightMMnsec);
autogenRegs.DEST.ambiguityRTD = autogenRegs.DEST.ambiguityRTD-single(1e-5);%????


regs = Firmware.mergeRegs(regs,autogenRegs);
end