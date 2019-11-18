function [regs,autogenRegs] = fwBootCalcs(regs,autogenRegs)
% calculate FRMW register for outside infrastructure
% calculates camera intrinsic
% The calculations produces: FRMW.kRaw,
% FRMW.kWorld,FRMW.zoRaw,FRMW.zoWorld, FRMW.depthOffset, FRMW.hscanDirR2L,FRMW.vscanDirD2U 
% function inputs:
% regs from previous bootcalc:regs.DEST.p2axa,regs.DEST.p2aya, regs.DEST.p2axb ,regs.DEST.p2ayb
%  Regs from external configuration:regs.GNRL.imgHsize,regs.GNRL.imgVsize
% regs from EPROM: regs.FRMW.zoRawCol,regs.FRMW.zoRawRow,regs.DEST.hbaseline
% regs.FRMW.calImgHsize,regs.FRMW.calImgVsize
%%
KinvRaw=[regs.DEST.p2axa            0                   regs.DEST.p2axb;
    0                regs.DEST.p2aya               regs.DEST.p2ayb;
    0                0                   1    ];
if ~regs.JFIL.upscalexyBypass
    if regs.JFIL.upscalex1y0
        KinvRaw(1,1) = KinvRaw(1,1)*single(regs.GNRL.imgHsize-1)/single(regs.FRMW.externalHsize-1);
    else
        KinvRaw(2,2) = KinvRaw(2,2)*single(regs.GNRL.imgVsize-1)/single(regs.FRMW.externalVsize-1);
    end
end

KRaw=inv(KinvRaw);
KRaw=abs(KRaw); % Make it so the K matrix is positive. This way the orientation of the cloud point is identical to DS.
autogenRegs.FRMW.kRaw=typecast(KRaw([1 4 7 2 5 8 3 6]),'uint32');



% Calculate K matrix. Note - users image is rotated by 180 degrees in
% respect to our internal representation.
Kworld=KRaw;
Kworld(1,3)=single(regs.FRMW.externalHsize)-1-KRaw(1,3);
Kworld(2,3)=single(regs.FRMW.externalVsize)-1-KRaw(2,3);



autogenRegs.CBUF.spare=typecast(Kworld([1 4 7 2 5 8 3 6]),'uint32');
autogenRegs.FRMW.kWorld=typecast(Kworld([1 4 7 2 5 8 3 6]),'uint32');
regs = Firmware.mergeRegs(regs,autogenRegs);

%% zero order
% calculate scale and shift
if(regs.FRMW.calImgHsize~=regs.GNRL.imgHsize || regs.FRMW.calImgVsize~=regs.GNRL.imgVsize)
    Hratio=double(regs.FRMW.externalHsize)/double(regs.FRMW.calImgHsize);
    Vratio=double(regs.FRMW.externalVsize)/double(regs.FRMW.calImgVsize);
    
    autogenRegs.FRMW.currZORawCol=regs.FRMW.zoRawCol(1)*Hratio;
    autogenRegs.FRMW. =regs.FRMW.zoRawRow(1)*Vratio;
    regs = Firmware.mergeRegs(regs,autogenRegs);
else
    autogenRegs.FRMW.currZORawCol=regs.FRMW.zoRawCol(1);
    autogenRegs.FRMW.currZORawRow=regs.FRMW.zoRawRow(1);
    regs = Firmware.mergeRegs(regs,autogenRegs);
end

% calculate world zero order
autogenRegs.FRMW.currZOWorldCol = uint32(regs.FRMW.externalHsize) - regs.FRMW.zoRawCol(1);
autogenRegs.FRMW.currZOWorldRow = uint32(regs.FRMW.externalVsize) - regs.FRMW.zoRawRow(1);
regs = Firmware.mergeRegs(regs,autogenRegs);

%% set depth offset constant: distance from the MEMS to the front case
if(regs.DEST.hbaseline==1) % demo-board
    autogenRegs.FRMW.depthOffset=single(5.7);
else % ID
    autogenRegs.FRMW.depthOffset=single(2);    
end
regs = Firmware.mergeRegs(regs,autogenRegs);

%% scan direction 
autogenRegs.FRMW.hscanDirR2L=1; 
autogenRegs.FRMW.vscanDirD2U=1; 
regs = Firmware.mergeRegs(regs,autogenRegs);

end

