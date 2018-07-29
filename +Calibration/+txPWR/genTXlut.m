function regs=genTXlut(hw,yfov,marginT,marginB)
    imHeight=hw.read('GNRLimgHsize');
    [~,lb]=hw.cmd('irb e2 06 01');%bias
    [~,lg]=hw.cmd('irb e2 08 01');%gain
    if(0)
        %%
        clear
        yfov=single(50); %#ok<*UNRCH>
        lb=uint8(20);
        lg=uint8(60);
        imHeight=uint16(480);
        marginT=uint16(0);
        marginB=uint16(0);
        lutA=genPWRlut(yfov,lb,lg,uint16(imHeight),uint16(marginT),uint16(marginB));

%         marginT=uint16(0);
%         marginB=uint16(0);
%         lutB=genPWRlut(yfov,lb,lg,uint16(imHeight),uint16(marginT),uint16(marginB));

        
        plot(0:64,lutA*1024,'.-');
        set(gca,'ylim',[-6 0]);
        set(gca,'xlim',[0 64]);
        [lutA(1) lutA(end)]*1024
    end
    regs.DEST.txPWRpd=Calibration.txPWR.genPWRlut(single(yfov),lb,lg,uint16(imHeight),uint16(marginT),uint16(marginB));
end


%{
test case:

%}