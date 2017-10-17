function [ depth,  confOut ,roundTripDistance, ir,peak_val_norm] = DEST( pflow,regs,~, lgr,traceOutDir )
%DEST calculates the depth (from the focal plane to the object)
%using correlation.
%   Inputs:
%   pflow.corrFine - an index to where the fine correlation should be performed.
%   pflow.corrOffset - is the location of the fine index in the bigger frame.
%   regs - access to register space.
%   pipeOutData.pflow.iImg - is I(ir) which is AN INDEX TO AN LUT that represents
%   the intensity dependant propagation delay.
%   Outputs:
%   depth - AKA zImg.
%   confidence level.



% lgr.print2file('\n\t------- DEST -------\n');

if (regs.DEST.bypass || isempty(pflow.pixIndOutOrder))
    depth = zeros(size(pflow.pipeFlags), 'uint16');
    confOut = zeros(size(pflow.pipeFlags), 'uint8');
    ir = pflow.iImgRAW;
    roundTripDistance = single(nan(size(pflow.pipeFlags)));
    
    cor_seg_fil = zeros(size(pflow.corr),'uint32');
    peak_val = zeros(size(ir),'uint32');
    peak_index = zeros(size(ir),'single');
    peak_val_norm = zeros(size(ir),'uint8');
    
    
    
else
%     lgrOutPixIndx = [];
%     if regs.MTLB.loggerOutPixelIndex < length(pflow.pixIndOutOrder)
%         lgrOutPixIndx = pflow.pixIndOutOrder(regs.MTLB.loggerOutPixelIndex+1);
%     end
    ir = pflow.iImgRAW;
    
    
    noScanPixels = reshape(accumarray(pflow.pixIndOutOrder(:),ones(numel(pflow.pixIndOutOrder),1),[double(regs.GNRL.imgHsize)*double(regs.GNRL.imgVsize) 1]),[regs.GNRL.imgVsize regs.GNRL.imgHsize])==0; %do not change thos pixels since they do not reach DEST in HW implementation (filled with 0 by CBUF)
    
    

    
    %since 000 is the LSB(bin 3), it needs to set 1Ghz (thus need to inverse txmode:
    %txmode=0 --> 1Ghz --> reg(1)
    %txmode=1 --> 0.5Ghz --> reg(2)
    %txmode=2 --> 0.5Ghz --> reg(3)
    %txmode=3 --> mixed mode pixels - should be removed
    txmode = bitand(bitshift(pflow.pipeFlags,-1),uint8(3))+1;
    mixModePixels = txmode==4;
    txmode(mixModePixels)=1; %treat txmode=3 as txmode=1, discard them later
    %% smooth
    mxv=64;
    ker = @(sr) ([sr;mxv-2*sr;sr]);
    
    cor_seg_fil = pflow.corr;
    cor_seg_fil=(pad_array(cor_seg_fil,4,0,'both'));
    cor_seg_fil = bitshift(convn(cor_seg_fil, ker( regs.DEST.smoothKerLen(1)), 'valid'),-6);
    cor_seg_fil = bitshift(convn(cor_seg_fil, ker( regs.DEST.smoothKerLen(2)), 'valid'),-6);
    cor_seg_fil = bitshift(convn(cor_seg_fil, ker( regs.DEST.smoothKerLen(3)), 'valid'),-6);
    cor_seg_fil = bitshift(convn(cor_seg_fil, ker( regs.DEST.smoothKerLen(4)), 'valid'),-6);
    cor_seg_fil = uint32(cor_seg_fil);
    
    
    %% find Qfunc
    
    
    % pflow.corrOffset correction (MSB index)
    
    corrOffset=pflow.corrOffset; %zero based
    corrOffset = uint16(corrOffset)*uint16( 2 ^ double(regs.DEST.decRatio));
    
    
    corrOffset = uint16(mod(int32(corrOffset)-int32(regs.DEST.fineCorrRange)  ,int32(regs.GNRL.tmplLength)));

    corrOffset = single(corrOffset)-1 ;
    
%     lgr.print2file(sprintf('\tcor_seg_fil=%s\n',sprintf('%08X ',flipud(cor_seg_fil(:,lgrOutPixIndx)))));
%     lgr.print2file(sprintf('\tcorrOffset(fine) = %02X\n',pflow.corrOffset(lgrOutPixIndx)));
    
    [peak_index, peak_val ] = Pipe.DEST.detectPeaks(cor_seg_fil,corrOffset,regs.MTLB.fastApprox(2));
    
%     lgr.print2file(sprintf('\tpeak_index = %X\n',peak_index(lgrOutPixIndx)));
%     lgr.print2file(sprintf('\tpeak_val = %X\n',peak_val(lgrOutPixIndx)));
%     
    %% quantize max_peak
    
    maxPeakMaxVal = (2^6-1);%hard coded
    
    peak_val_norm  = uint8(min(maxPeakMaxVal,bitshift(peak_val*regs.DEST.maxvalDiv,-14)-regs.DEST.maxvalSub));
%     lgr.print2file(sprintf('\tpeak_val_norm = %X\n',peak_val_norm(lgrOutPixIndx)));
    
    %% confidence
    confOut = Pipe.DEST.confBlock(pflow.dutyCycle,pflow.psnr,peak_val_norm,pflow.iImgRAW, regs);
%     lgr.print2file(sprintf('\tconfOut = %X\n',confOut(lgrOutPixIndx)));
    
    %% Calculate angles
    
    
    
    
    %% Calculate round trip distance
    roundTripDistance = peak_index .* map(regs.DEST.sampleDist, txmode);
    
%     lgr.print2file(sprintf('\troundTripDistance = %X\n',roundTripDistance(lgrOutPixIndx)));
    
   roundTripDistance = Pipe.DEST.rtdDelays(roundTripDistance,regs,pflow.iImgRAW,txmode);
   
   
   
    confOut(noScanPixels | mixModePixels)=0;
    roundTripDistance(noScanPixels | mixModePixels)=0;
    
%     lgr.print2file(sprintf('\troundTripDistance(ambiguity length fix) = %X\n',roundTripDistance(lgrOutPixIndx)));
    
    
    %% ambiguity filter
    closeRangeLowConf = roundTripDistance<regs.DEST.ambiguityMinRTD & confOut<regs.DEST.ambiguityMinConf & ~noScanPixels;
    roundTripDistance(closeRangeLowConf)=vec(roundTripDistance(closeRangeLowConf)) + vec(regs.DEST.ambiguityRTD(txmode(closeRangeLowConf)));

%     lgr.print2file(sprintf('\troundTripDistance(ambiguity filter) = %X\n',roundTripDistance(lgrOutPixIndx)));


    %% rtd2depth
    depth=Pipe.DEST.rtd2depth(roundTripDistance,regs);
    depth = depth*regs.GNRL.zNorm;
%     lgr.print2file(sprintf('\tdepth(pre round) = %X\n',typecast(depth(lgrOutPixIndx),'uint32')));
    depth=uint16 (floor(max(1,depth+.5)));
%     lgr.print2file(sprintf('\tdepth(post round) = %X\n',depth(lgrOutPixIndx)));
    
    confOut(noScanPixels)=0;
    depth(noScanPixels)=0;
    

%     lgr.print2file(sprintf('\troundTripDistance(ambiguity length fix) = %X\n',roundTripDistance(lgrOutPixIndx)));

    %% AlternativeIR
    if(regs.DEST.altIrEn)
        %%
        ir = peak_val;
        ir = ir-regs.DEST.altIrSub; %values lower than zero are truncated to zero
        ir = ir*uint32(regs.DEST.altIrDiv);
        ir = bitshift(ir,-16);
        ir = uint16(ir);
        ir = min(ir,2^12-1);%values greater than 2^12-1 are saturated to 2^12-1
    end
    
    
    
end % bypass




%% TRACER
if(~isempty(traceOutDir) )
    %DEST_out
    %{
    ma_algo_i.ma_dest_i.dest_cbuf_x_loc[55:44] ,
    1'b0,
    ma_algo_i.ma_dest_i.dest_cbuf_y_loc[42:32],
    ma_algo_i.ma_dest_i.dest_cbuf_depth[31:16],
    ma_algo_i.ma_dest_i.dest_cbuf_ir[15:4],
    ma_algo_i.ma_dest_i.dest_cbuf_conf[3:0]
    %}
    pio=pflow.pixIndOutOrder;
    [yg,xg]=ind2sub([regs.GNRL.imgVsize regs.GNRL.imgHsize],pio);
    yg=yg-1;xg=xg-1;
    
    cor_seg_fil_txt = reshape(cor_seg_fil,size(cor_seg_fil,1),[]);
    cor_seg_fil_txt = [zeros(33-size(cor_seg_fil_txt,1),size(cor_seg_fil_txt,2));cor_seg_fil_txt];
    cor_seg_fil_txt = reshape(dec2hexFast(cor_seg_fil_txt(:,pio),6)',6*33,[])';
    
    Utils.buildTracer(cor_seg_fil_txt,'DEST_cor_seg_fil',traceOutDir);
    
    Utils.buildTracer([dec2hexFast(peak_val(pio)) dec2hexFast(peak_index(pio))],'DEST_peak_indexval',traceOutDir);
    
    Utils.buildTracer(dec2hexFast(peak_val_norm(pio)),'DEST_peak_val_norm',traceOutDir);
    
    
    
    
    DESTtxt = [dec2hexFast(xg,3) dec2hexFast(yg,3) dec2hexFast(depth(pio),4) dec2hexFast(ir(pio),3) dec2hexFast(confOut(pio),1)];
    Utils.buildTracer(DESTtxt,'DEST_out',traceOutDir);
end

% lgr.print2file('\t----- end DEST -----\n');

end


