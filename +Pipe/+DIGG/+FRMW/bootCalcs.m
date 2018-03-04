function [regs,autogenRegs,autogenLuts] = bootCalcs(regs,luts,autogenRegs,autogenLuts)



%=======================================DIGG - ang2xy=======================================
t = Pipe.DIGG.FRMW.getAng2xyCoeffs(regs);
autogenRegs = Firmware.mergeRegs(autogenRegs,t);
%=======================================DIGG - spherical=======================================
 
alpha = 2^12/4095*[1-regs.FRMW.xR2L*2 1-regs.FRMW.yflip*2];
autogenRegs.DIGG.sphericalScale=int16(round(double([regs.FRMW.xres regs.FRMW.yres]).*alpha));
autogenRegs.DIGG.sphericalOffset=int16(round([double(regs.FRMW.xres)/2-double(regs.FRMW.marginL) double(regs.FRMW.yres)/2-double(regs.FRMW.marginT)].*[4 1]));

regs = Firmware.mergeRegs(regs,autogenRegs);
%=======================================DIGG - notch filters=======================================

[b,a] = Pipe.DIGG.FRMW.getNotchFilterCoeffs(regs);
avec = typecast(vec(a'),'uint32');
bvec = typecast(vec(b'),'uint32');
for i=1:size(avec,1)
    

    
    autogenRegs.DIGG.notchA(i)= (avec(i));
    autogenRegs.DIGG.notchB(i) = (bvec(i));

    
end

% %=======================================DIGG - iptg=======================================
% 
%  iptgMirrorFreq = 20000;
% 
% 
% iptgNx = 19;
% 
% 
% %ir
% autogenRegs.DIGG.iptgNpPackets = double(regs.GNRL.sampleRate)*1e9/(double(regs.DIGG.iptgFrameRate)*64);
% autogenRegs.DIGG.iptgPktsPerScanLine =floor( double(regs.GNRL.sampleRate)*1e9/(2*64*iptgMirrorFreq));
% 
% if(regs.GNRL.sampleRate==4)
%     iptgNy=22;
% else
%     iptgNy=25;
% end
% 
% autogenRegs.DIGG.iptgPktsPerCB = autogenRegs.DIGG.iptgPktsPerScanLine/iptgNy;
% autogenRegs.DIGG.iptgPktsPerScanBlock = regs.DIGG.iptgPktsPerScanLine*iptgNx;
% 
% %xy
% autogenRegs.DIGG.iptgAngxNpackets = autogenRegs.DIGG.iptgPktsPerScanLine;
% autogenRegs.DIGG.iptgAngxDelta =ceil(2^12/(autogenRegs.DIGG.iptgNpPackets/autogenRegs.DIGG.iptgPktsPerScanLine-1));
% 
% autogenRegs.DIGG.iptgAngyDelta =ceil(2^12/autogenRegs.DIGG.iptgPktsPerScanLine );
% autogenRegs.DIGG.iptgAngyNpackets =floor(autogenRegs.DIGG.iptgPktsPerScanLine*autogenRegs.DIGG.iptgAngyDelta/2^12 );
% 
% 
% 
% %chk
% autogenRegs.DIGG.iptgAngyNpackets   = convertChk(autogenRegs.DIGG.iptgAngyNpackets);
% autogenRegs.DIGG.iptgAngyDelta      = convertChk(autogenRegs.DIGG.iptgAngyDelta      );
% autogenRegs.DIGG.iptgAngxDelta      = convertChk(autogenRegs.DIGG.iptgAngxDelta      );
% autogenRegs.DIGG.iptgAngxNpackets   = convertChk(autogenRegs.DIGG.iptgAngxNpackets   );
% autogenRegs.DIGG.iptgPktsPerCB      = convertChk(autogenRegs.DIGG.iptgPktsPerCB      );
% autogenRegs.DIGG.iptgPktsPerScanLine= convertChk(autogenRegs.DIGG.iptgPktsPerScanLine);
% autogenRegs.DIGG.iptgNpPackets      = convertChk(autogenRegs.DIGG.iptgNpPackets      );
% autogenRegs.DIGG.iptgTxCode = regs.FRMW.txCode;
% regs = Firmware.mergeRegs(regs,autogenRegs);


%=======================================DIGG - undist=======================================
[autogenRegs_,autogenLuts_] = Pipe.DIGG.FRMW.buildLensLUT(regs,luts);
autogenRegs = Firmware.mergeRegs(autogenRegs,autogenRegs_);
autogenLuts = Firmware.mergeRegs(autogenLuts,autogenLuts_);

regs = Firmware.mergeRegs(regs,autogenRegs);
%=======================================DIGG - gamma LUT=======================================

X = linspace(0,1,65);
outLut = X.^(regs.FRMW.diggGammaFactor);
% autogenRegs.DIGG.gamma = uint16([outLut*(2^12-1) 0 ]);

regs = Firmware.mergeRegs(regs,autogenRegs);

end


% function vout=convertChk(v)
% vout=uint32(v);
%  assert(double(vout)==double(v));
% end
