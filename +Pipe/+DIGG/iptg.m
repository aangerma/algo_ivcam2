function [fast,slow,xyQ,flags]=iptg(regs,luts)
















%% XY angle

%increment by a value of regs.DIGG.iptgAngxDelta every
%regs.DIGG.iptgAngxNpackets samples.
angx = buffer_(zeros(1,regs.DIGG.iptgNpPackets),regs.DIGG.iptgAngxNpackets);
angx = vec(bsxfun(@plus,angx,(0:size(angx,2)-1)*double(regs.DIGG.iptgAngxDelta)));
angx = min(angx(1:regs.DIGG.iptgNpPackets),2^12-1)-2^11;
%
angy = buffer_(zeros(1,regs.DIGG.iptgPktsPerScanLine),regs.DIGG.iptgAngyNpackets);
angy = vec(bsxfun(@plus,angy,(0:size(angy,2)-1)*double(regs.DIGG.iptgAngyDelta)));
angy = [angy;flipud(angy)];
angy=repmat(angy,ceil(double(regs.DIGG.iptgNpPackets)/length(angy )),1);
angy = min(angy(1:regs.DIGG.iptgNpPackets),2^12-1)-2^11;
xyQ = int16([angx angy]');
% plot(slow, fast)
%% fast

codevec = vec(fliplr(dec2bin(regs.DIGG.iptgTxCode(:),32))')=='1';


k = vec(uint8(codevec(1:regs.GNRL.codeLength)))';
k = vec(repmat(k,regs.GNRL.sampleRate,1))';
k = circshift(k,[0,regs.DIGG.iptgDepthOffset]);
fast=repmat(k,ceil(double(regs.DIGG.iptgNpPackets)*64/double(regs.GNRL.tmplLength)),1)';
fast = fast(1:regs.DIGG.iptgNpPackets*64);

%% slow

%create vertical strips image

slowB = false(1,regs.DIGG.iptgNpPackets);
slowB = flipEveryN(slowB,regs.DIGG.iptgPktsPerCB);
slowB = flipEveryN(slowB,regs.DIGG.iptgPktsPerScanLine);
slowB = flipEveryN(slowB,regs.DIGG.iptgPktsPerScanBlock);



slow = uint16(slowB);
slow(slowB==0)=regs.DIGG.iptgIRlow;
slow(slowB==1)=regs.DIGG.iptgIRhi;
slow( xyQ(2,:)==-2^11 | xyQ(2,:)==2^11-1)=regs.DIGG.iptgIRoff;

% plot(angx(slowB==1),angy(slowB==1),'.',angx(slowB==0),angy(slowB==0),'.');
% axis equal
%% flags
flags_ld_on = xyQ(2,:)~=-2^11 & xyQ(2,:)~=2^11-1;
flags_tx_code_start = zeros(1,regs.DIGG.iptgNpPackets);flags_tx_code_start(1)=1;
flags_scan_dir = flipEveryN(false(1,regs.DIGG.iptgNpPackets),regs.DIGG.iptgPktsPerScanLine);
flags_tx_rx_mode = zeros(1,regs.DIGG.iptgNpPackets);
flags = bitshift(uint8(flags_ld_on)        ,0)+...
    bitshift(uint8(flags_tx_code_start),1)+...
    bitshift(uint8(flags_scan_dir)     ,2)+...
    bitshift(uint8(flags_tx_rx_mode)   ,3);





end

function vout=flipEveryN(v,N)
vout = buffer_(v,N);
fv = (-1).^(0:size(vout,2)-1)>0;
vout = bsxfun(@xor,vout,fv);
vout = vout(1:length(v));
end