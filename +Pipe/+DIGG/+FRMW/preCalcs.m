function [regs,autogenRegs,autogenLuts] = preCalcs(regs,luts,autogenRegs,autogenLuts)

%=======================================DIGG - ang2xy- calib res =======================================
tmpRegs=regs; 
tmpRegs.GNRL.imgHsize=regs.FRMW.calImgHsize; 
tmpRegs.GNRL.imgVsize=regs.FRMW.calImgVsize; 
tmpRegs.FRMW.marginL=regs.FRMW.calMarginL; 
tmpRegs.FRMW.marginR=regs.FRMW.calMarginR; 
tmpRegs.FRMW.marginT=regs.FRMW.calMarginT; 
tmpRegs.FRMW.marginB=regs.FRMW.calMarginB; 

t = Pipe.DIGG.FRMW.getAng2xyCoeffs(tmpRegs);
autogenRegs = Firmware.mergeRegs(autogenRegs,t);

regs = Firmware.mergeRegs(regs,autogenRegs);


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
% calculate block rectangle of pincushion
tmpRegs=regs; 
tmpRegs.GNRL.imgHsize=regs.FRMW.calImgHsize; 
tmpRegs.GNRL.imgVsize=regs.FRMW.calImgVsize; 
tmpRegs.FRMW.marginL=regs.FRMW.calMarginL; 
tmpRegs.FRMW.marginR=regs.FRMW.calMarginR; 
tmpRegs.FRMW.marginT=regs.FRMW.calMarginT; 
tmpRegs.FRMW.marginB=regs.FRMW.calMarginB; 

[BlockRecRegs] = Pipe.DIGG.FRMW.calculateAng2xyBlockRec(tmpRegs); 
autogenRegs = Firmware.mergeRegs(autogenRegs,BlockRecRegs);
regs = Firmware.mergeRegs(regs,autogenRegs);

% calculate location luts 
[undistLut] = Pipe.DIGG.FRMW.BuildUndistLut(regs,luts); 
autogenLuts = Firmware.mergeRegs(autogenLuts,undistLut);

%=======================================DIGG - gamma LUT=======================================

% X = linspace(0,1,65);
% outLut = X.^(regs.FRMW.diggGammaFactor);
% autogenRegs.DIGG.gamma = uint16([outLut*(2^12-1) 0 ]);

regs = Firmware.mergeRegs(regs,autogenRegs);
end

