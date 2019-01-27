function [regs,autogenRegs,autogenLuts] = preCalcs(regs,luts,autogenRegs,autogenLuts)

autogenRegs.DEST.fineCorrRange = uint16(16);

%------------rx/txPWR LUT-----------------%
    
    %TODO: ROI (replace regs.GNRL.imgVsize with yres, truncate according to
    %margin)
%     txAxis = single(linspace(0,double(regs.GNRL.imgVsize),65));
%     rxAxis = single(linspace(0,4096/rxLUTscale,65));

%     stepFunc = @(x,th) th(1)*(.5-.5*erf((x-th(2))*th(3)));
%      autogenRegs.DEST.txPWRpd =stepFunc(txAxis/double(regs.GNRL.imgVsize),regs.FRMW.destTxpdGen);
%     autogenRegs.DEST.rxPWRpd =stepFunc(rxAxis,regs.FRMW.destRxpdGen);
%    plot(rxAxis,autogenRegs.DEST.rxPWRpd)
    %interpolation
%     autogenRegs.DEST.txPWRpd=autogenRegs.DEST.txPWRpd/2^10;
%     autogenRegs.DEST.rxPWRpd=autogenRegs.DEST.rxPWRpd/2^10;
    
% % % autogenRegs.DEST.txPWRpd=zeros(1,65,'single')/2^10; %set by firmware in runtime from laser power
regs = Firmware.mergeRegs(regs,autogenRegs);
end

