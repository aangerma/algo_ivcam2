function [slow,xyQ, nest ,roiFlag] = DIGG( indata, regs,luts,lgr,traceOutDir )


lgr.print2file('\n\t------- DIGG -------\n');


% if(regs.DIGG.iptgBypass)
xyQ = indata.xy;
flags=indata.flags;
slow = indata.slow;
fast = indata.fast;
% else
%     [fast,slow,xyQ,flags]=Pipe.DIGG.iptg(regs,luts);
% end

%% input tracers
if(~isempty(traceOutDir))
    % {3'b000,ma_algo_i.ma_digg_i.ana_sync_digg_ldon[115:112]
    % 3'b000,ma_algo_i.ma_digg_i.ana_sync_digg_tx_code_start[111:108]
    % 3'b000,ma_algo_i.ma_digg_i.ana_sync_digg_scan_dir[107:104]
    % 2'b00,ma_algo_i.ma_digg_i.ana_sync_digg_tx_rx_mode[101:100]
    % ma_algo_i.ma_digg_i.ana_sync_digg_angx[99:88]
    % ma_algo_i.ma_digg_i.ana_sync_digg_angy[87:76]
    % ma_algo_i.ma_digg_i.ana_sync_digg_ir[75:64]
    % ma_algo_i.ma_digg_i.ana_sync_digg_fast[63:0]}
    
    txCodeStartBitNum = 1; %starts from 0...
    txCodeStartH = dec2hexFast(uint8(bitshift(double(bitand(flags,2^txCodeStartBitNum,'uint8')),-txCodeStartBitNum)),1);
    ldonBitNum = 0; %starts from 0...
    ldonH = dec2hexFast(uint8(bitshift(double(bitand(flags,2^ldonBitNum,'uint8')),-ldonBitNum)),1);
    scanDirBitNum = 2; %starts from 0...
    scanDirH = dec2hexFast(uint8(bitshift(double(bitand(flags,2^scanDirBitNum,'uint8')),-scanDirBitNum)),1);
    txrxModeBitNum = 3:4; %starts from 0...
    txrxModeH = dec2hexFast(uint8(bitshift(double(bitand(flags,sum(2.^txrxModeBitNum),'uint8')),-min(txrxModeBitNum))),1);
    
    txtOut=[
        ldonH txCodeStartH scanDirH txrxModeH...
        dec2hexFast(xyQ(1,:),3)...
        dec2hexFast(xyQ(2,:),3)...
        dec2hexFast(slow,3)...
        logical2hex(fast)...
        ];
    Utils.buildTracer(txtOut,'DIGG_in',traceOutDir);
end

flag_scan_dir = logical(bitget(flags,3));

[xyQ, roiFlag] = Pipe.DIGG.GENG(xyQ,flag_scan_dir,regs,luts,lgr,traceOutDir);


% lgr.print2file(sprintf('\tangxQ = %03X\n\tangyQ = %s\n\tfast = %s\n\tslow = %s\n\tflags = %02X\n',  xyQ(1,1),xyQ(2,1),logical2hex(fast(1:64)),   dec2hexFast(slow(1),3),flags(1)));


%% GAMMA
if(~regs.DIGG.gammaBypass)
    slow = Utils.applyGamma(slow,12,regs.DIGG.gamma(1:end-1),12,regs.DIGG.gammaScale, regs.DIGG.gammaShift  );
    slow = uint16(slow);%do not move this line up so the functionDependencyWalker will see apply gamma
end
vslowGammaOnly = slow;


% lgr.print2file(sprintf('\tslow (GAMMA output) = %03X\n',slow(1)));


%% NOTCH FILTER
slow =Pipe.DIGG.notchFilter(slow,regs);

assert(nnz(slow > 4095) == 0, 'IR values are 12 bits');

%% DIALLOW ZERO VALUES
slow = max(slow,1);



% lgr.print2file(sprintf('\tslow (NOTCH output) = %s\n',dec2hexFast(slow(1),3)));


%% NEST
if(~regs.DIGG.nestBypass)
    mRegs.NestNumOfSamplesExp = regs.DIGG.nestNumOfSamplesExp;
    mRegs.NestLdOnDelay = regs.DIGG.nestLdOnDelay;
    nest = Pipe.DIGG.NEST(slow, flags, mRegs);
else
    nest = ones(size(slow),'uint16');
end

assert(nnz(nest > 4095) == 0, 'NEST values are 12 bits');

%%
 
 
 switch(regs.MTLB.scanDirBypass)
     case 0
     case 1
         xyQ(2,flag_scan_dir)=-1;
     case 2
         xyQ(2,~flag_scan_dir)=-1;

 end

 


% lgr.print2file(sprintf('\tnest (NEST output) = %s\n',dec2hexFast(nest(1),3)));


%% TRACER
if(~isempty(traceOutDir) )
    %vslowGamma
    % |--- gamma (3 hex chars) ---|
    gammaH = dec2hexFast(vslowGammaOnly,3);
    Utils.buildTracer(gammaH,'DIGG_gamma',traceOutDir);
    
    
    
    
    
    %digg out
    nestH = dec2hexFast(nest,3);
    roiH = dec2hexFast(uint8(roiFlag),1);
    txCodeStartBitNum = 1; %starts from 0...
    txCodeStartH = dec2hexFast(uint8(bitshift(double(bitand(flags,2^txCodeStartBitNum,'uint8')),-txCodeStartBitNum)),1);
    ldonBitNum = 0; %starts from 0...
    ldonH = dec2hexFast(uint8(bitshift(double(bitand(flags,2^ldonBitNum,'uint8')),-ldonBitNum)),1);
    scanDirBitNum = 2; %starts from 0...
    scanDirH = dec2hexFast(uint8(bitshift(double(bitand(flags,2^scanDirBitNum,'uint8')),-scanDirBitNum)),1);
    txrxModeBitNum = 3:4; %starts from 0...
    txrxModeH = dec2hexFast(uint8(bitshift(double(bitand(flags,sum(2.^txrxModeBitNum),'uint8')),-min(txrxModeBitNum))),1);
    
    txtOut=[
        nestH...
        roiH...
        ldonH txCodeStartH scanDirH txrxModeH...
        dec2hexFast(xyQ(1,:),4)...
        dec2hexFast(xyQ(2,:),3)...
        dec2hexFast(slow,3)...
        logical2hex(fast)...
        ];
    Utils.buildTracer(txtOut,'DIGG_out',traceOutDir);
    
    
    

    
    
end


lgr.print2file('\t----- end DIGG -----\n');

end


