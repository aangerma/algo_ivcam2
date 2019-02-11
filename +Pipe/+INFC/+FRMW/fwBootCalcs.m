function [regs,autogenRegs] = fwBootCalcs(regs,autogenRegs)
% calculate FRMW register for outside infrastructure
% calculates camera intrinsic
% The calculations produces: FRMW.kRaw, FRMW.kWorld,FRMW.zoRaw,FRMW.zoWorld
% function inputs:
% regs from previous bootcalc:regs.DEST.p2axa,regs.DEST.p2aya, regs.DEST.p2axb ,regs.DEST.p2ayb
%  Regs from external configuration:regs.GNRL.imgHsize,regs.GNRL.imgVsize
% regs from EPROM: regs.FRMW.zoRawCol,regs.FRMW.zoRawRow,
% regs.FRMW.calImgHsize,regs.FRMW.calImgVsize
%%
KinvRaw=[regs.DEST.p2axa            0                   regs.DEST.p2axb;
    0                regs.DEST.p2aya               regs.DEST.p2ayb;
    0                0                   1    ];
KRaw=inv(KinvRaw);
KRaw=abs(KRaw); % Make it so the K matrix is positive. This way the orientation of the cloud point is identical to DS.
autogenRegs.FRMW.kRaw=typecast(KRaw([1 4 7 2 5 8 3 6]),'uint32');



% Calculate K matrix. Note - users image is rotated by 180 degrees in
% respect to our internal representation.
Kworld=KRaw;
Kworld(1,3)=single(regs.GNRL.imgHsize)-1-KRaw(1,3);
Kworld(2,3)=single(regs.GNRL.imgVsize)-1-KRaw(2,3);

autogenRegs.CBUF.spare=typecast(Kworld([1 4 7 2 5 8 3 6]),'uint32');
autogenRegs.FRMW.kWorld=typecast(Kworld([1 4 7 2 5 8 3 6]),'uint32');
regs = Firmware.mergeRegs(regs,autogenRegs);

%% zero order
% calculate scale and shift
if(regs.FRMW.calImgHsize~=regs.GNRL.imgHsize || regs.FRMW.calImgVsize~=regs.GNRL.imgVsize)
    Hratio=double(regs.GNRL.imgHsize)/double(regs.FRMW.calImgHsize);
    Vratio=double(regs.GNRL.imgVsize)/double(regs.FRMW.calImgVsize);
    autogenRegs.FRMW.zoRawCol=regs.FRMW.zoRawCol*Hratio;
    autogenRegs.FRMW.zoRawRow=regs.FRMW.zoRawRow*Vratio;
    regs = Firmware.mergeRegs(regs,autogenRegs);
else
    autogenRegs.FRMW.zoRawCol=regs.FRMW.zoRawCol;
    autogenRegs.FRMW.zoRawRow=regs.FRMW.zoRawRow;
    regs = Firmware.mergeRegs(regs,autogenRegs);
end

% calculate world zero order
autogenRegs.FRMW.zoWorldCol = uint32(regs.GNRL.imgHsize)*uint32(ones(1,5)) - regs.FRMW.zoRawCol;
autogenRegs.FRMW.zoWorldRow =uint32(regs.GNRL.imgVsize)*uint32(ones(1,5)) - regs.FRMW.zoRawRow;
regs = Firmware.mergeRegs(regs,autogenRegs);


end

