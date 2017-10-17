function [fast,slow,xy,flags] = ASNC( indata,regs,luts,lgr,traceOutDir )%#ok
%ASNC Summary of this function goes here
%   Detailed explanation goes here


%%apply ASIC delays


fd = regs.MTLB.fastChDelay;
sd = regs.MTLB.slowChDelay;

%{
slowxySampleRate = single(regs.GNRL.sampleRate)/64;
fd = int32(single(regs.CLBR.fastChDelayNsec)*slowxySampleRate*single(1));
sd = int32(single(regs.CLBR.slowChDelayNsec)*slowxySampleRate*single(1));
%}
slow = circshift(indata.slow,[0 sd]);
fast = circshift(indata.fast,[0 fd*64]);
% flags  = circshift(bitand(indata.flags , uint8(2)),[0 fd])+ bitand(indata.flags , bitxor(uint8(2),255));

LD_ON_BIT=1;
TX_CD_STRT_BIT=2;
SCAN_DIR=3;
TXRX_MODE_BIT0=4;
TXRX_MODE_BIT1=5;

flags_ld_on = bitget(indata.flags,LD_ON_BIT);
flags_cd_strt =bitget(indata.flags,TX_CD_STRT_BIT);
flags_scan_dir = bitget(indata.flags,SCAN_DIR);
flags_txrx0 = bitget(indata.flags,TXRX_MODE_BIT0);
flags_txrx1 = bitget(indata.flags,TXRX_MODE_BIT1);


flags_ld_on = circshift(flags_ld_on,[0 sd]);
flags_cd_strt = circshift(flags_cd_strt,[0 fd]);
flags_scan_dir = circshift(flags_scan_dir,[0 0]);
flags_txrx0= circshift(flags_txrx0,[0 sd]);
flags_txrx1= circshift(flags_txrx1,[0 sd]);

flags  = bitshift(flags_ld_on,LD_ON_BIT-1)+...
    bitshift(flags_cd_strt,TX_CD_STRT_BIT-1)+...
    bitshift(flags_scan_dir,SCAN_DIR-1)+...
    bitshift(flags_txrx0,TXRX_MODE_BIT0-1)+...
    bitshift(flags_txrx1,TXRX_MODE_BIT1-1);
xy = indata.xy;

end



