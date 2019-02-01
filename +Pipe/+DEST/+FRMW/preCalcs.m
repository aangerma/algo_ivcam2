function [regs,autogenRegs,autogenLuts] = preCalcs(regs,luts,autogenRegs,autogenLuts)


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



%% zero order location
%ZOLOC calculates the location of the ZO pixel (in the users rectified
%image).
regs = Firmware.mergeRegs(regs,autogenRegs);
FElut=Utils.feVec2Mat(regs,autogenLuts); 
[xZOraw,yZOraw] = Calibration.aux.ang2xySF(0,0,regs,FElut,1); % ZO location
autogenRegs.FRMW.zoRawCol= uint32(floor(xZOraw))*uint32(ones(1,5));
autogenRegs.FRMW.zoRawRow= uint32(floor(yZOraw))*uint32(ones(1,5));


%%
regs = Firmware.mergeRegs(regs,autogenRegs);
end

