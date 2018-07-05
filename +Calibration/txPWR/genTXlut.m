function regs=genTXlut(hw)
    [~,yfov]=hw.read('0xA0020BE0');
    yfov=typecast(yfov,'single');
    [~,lb]=hw.cmd('irb e2 06 01');%bias
    [~,lg]=hw.cmd('irb e2 08 01');%gain
    regs.DEST.txPWRpd=genPWRlut(yfov,lb,lg);
end