function rtdout=rtdDelays(rtdin,regs,ir,txmode)
[yi,xi]=ndgrid(0:double(regs.GNRL.imgVsize)-1,0:double(regs.GNRL.imgHsize)-1);
    
    %LUT inputs are [-127 127]

%% reduce prop. delay
txPWRpdScale = map(regs.DEST.txPWRpdScale, txmode);
rxPWRpdScale = map(regs.DEST.rxPWRpdScale, txmode);


%if range finder mode, use x coordinate, otherwise, use y coordinate
ci = iff(regs.GNRL.rangeFinder,xi,yi);
%regs.DEST.txPWRpdLUTfactor - 32b
%ci - 10b(max, on RF mode discard top bit)
%after multiplication+bitshift saturate to 16b
txLUTindex = uint16(bitshift(uint64(ci)           *uint64(regs.DEST.txPWRpdLUTfactor)+2^15,-16));
rxLUTindex = uint16(bitshift(uint64(ir)*uint64(regs.DEST.rxPWRpdLUTfactor)+2^15,-16));
txpdval = interpLUTval(regs.DEST.txPWRpd,txLUTindex).* txPWRpdScale;
rxpdval = interpLUTval(regs.DEST.rxPWRpd,rxLUTindex).* rxPWRpdScale;


txFRQpd = map(regs.DEST.txFRQpd, txmode);

rtdout = rtdin -rxpdval - txpdval  - txFRQpd;

%     lgr.print2file(sprintf('\troundTripDistance(tx/rx delay) = %X\n',roundTripDistance(lgrOutPixIndx)));
rtdout=rtdout*regs.DEST.tmptrScale + regs.DEST.tmptrOffset;
%     lgr.print2file(sprintf('\troundTripDistance(Thermal fix) = %X\n',roundTripDistance(lgrOutPixIndx)));


%% Remove ambiguity length
ambiguityLenLocs = rtdout > map(regs.DEST.ambiguityRTD, txmode);
rtdout(ambiguityLenLocs) = vec(rtdout(ambiguityLenLocs))- vec(regs.DEST.ambiguityRTD(txmode(ambiguityLenLocs)));

ambiguityLenLocs = rtdout<0;
rtdout(ambiguityLenLocs) = vec(rtdout(ambiguityLenLocs))+ vec(regs.DEST.ambiguityRTD(txmode(ambiguityLenLocs)));

end

function val = interpLUTval(lut,index)
indlw = bitshift(index,-10)+1;%6MSB,+1 for matlab
ind0 = single(bitand(  index,2^10-1));%10LSB
ind1 = single(2^10-ind0);
val = lut(indlw).*ind1+lut(indlw+1).*ind0; %division by 1024 are preformed in LUT values
end
