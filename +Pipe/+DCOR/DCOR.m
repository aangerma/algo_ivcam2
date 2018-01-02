function  [corrOffset, corrSegment, psnr_value, iImgRAW,tmplIndex] = DCOR(pflow,regs,luts, lgr,traceOutDir)

% lgr.print2file('\n\t------- DCOR -------\n');

assert(max(pflow.cma(:))<128); %cma should be always 7b
cma_ = min(63, bitshift(pflow.cma+1,-1));

    nF = double(regs.GNRL.tmplLength);
    nC = double(regs.DCOR.coarseTmplLength);


uint82uint4 = @(v) vec([bitand(v(:),uint8(15)) bitshift(v(:),-4)]');
mem2tbl = @(v) reshape(flipud(reshape(uint82uint4 (typecast(v,'uint8')),8,[])),[],64);
tmplC = mem2tbl (luts.DCOR.tmpltCrse);
tmplF = mem2tbl (luts.DCOR.tmpltFine);


tmplF  = circshift(tmplF ,[-nF+16,16]);
if (regs.DCOR.bypass || isempty(pflow.pixIndOutOrder)) %bypass or no pixels
    corrOffset = zeros(size(pflow.pipeFlags), 'uint16');
    fCorrSize = regs.DCOR.fineCorrRange * 2 + 1;
    corrSegment = zeros([fCorrSize size(pflow.pipeFlags)], 'uint32');
    psnr_value = zeros(size(pflow.pipeFlags), 'uint8');
    iImgRAW = pflow.iImgRAW;
    cma_dec=zeros(size(cma_)./[2^double(regs.DCOR.decRatio) 1 1],'uint32');
    cor_dec_masked=zeros(size(cma_)./[2^double(regs.DCOR.decRatio) 1 1],'uint32');
    tmplIndex =  zeros(size(pflow.pipeFlags), 'uint8');
else
%     lgrOutPixIndx = [];
%     if regs.MTLB.loggerOutPixelIndex < length(pflow.pixIndOutOrder)
%         lgrOutPixIndx = pflow.pixIndOutOrder(regs.MTLB.loggerOutPixelIndex+1);
%     end
%     
%     
    
    % sampleRate = double(regs.GNRL.sampleRate);
    downSamplingR = 2 ^ double(regs.DCOR.decRatio);
    % cfs = double(regs.GNRL.sampleRate) / sc0;
    %% PSNR
    iImgRAW = pflow.iImgRAW;
    dIR = max(0, int16(iImgRAW)-int16(regs.DCOR.irStartLUT));
    irIndex = map(regs.DCOR.irMap,    min(63, bitshift(dIR, -int8(regs.DCOR.irLUTExp))  )   +1);
    
    amb = pflow.aImg;
    dAmb = max(0, int16(amb)-int16(regs.DCOR.ambStartLUT));
    ambIndex = map(regs.DCOR.ambMap, min(63, bitshift(dAmb, -int8(regs.DCOR.ambLUTExp)))+1);
    
    psnrIndex = bitor(bitshift(ambIndex, 4), irIndex);
    psnr_value = map(regs.DCOR.psnr, uint16(psnrIndex)+1);
    
%     lgr.print2file(sprintf('\tpsnr_value = %X\n',psnr_value(lgrOutPixIndx)));
   %% 
    [ys, xs] = ndgrid(0:regs.GNRL.imgVsize-1, 0:regs.GNRL.imgHsize-1);
    
    
    txRx = bitand(bitshift(pflow.pipeFlags, -1), 3);
    %tmplIndex is from [0-63]
    if(regs.GNRL.rangeFinder)
        yIndex = uint8(bitand(xs,1));
        tmplIndex = bitor(bitshift(yIndex,4), uint8(bitshift(psnr_value, -2)));
        assert(max(tmplIndex(:))<=31);
        tmplC=tmplC(:,1:32);
        tmplF=reshape(tmplF,2048,32);

    else
        switch (regs.DCOR.tmplMode)
            case 0% RXONLY
                tmplIndex = psnr_value;
            case 1 % RXTX
                yIndex = regs.DCOR.yScaler(bitand(127,bitshift(ys, -int8(regs.DCOR.yScalerDivExp)))+1);
                yIndex = bitshift(yIndex, int8(regs.DCOR.yScalerBits)-3);
                
                tmplIndex = bitor(bitshift(yIndex, 6-int8(regs.DCOR.yScalerBits)), ...
                    bitshift(psnr_value, -int8(regs.DCOR.yScalerBits)));
            case 2 % RXFREQ
                tmplIndex = bitor(bitshift(txRx, 4), uint8(bitshift(psnr_value, -2)));
            otherwise
                error('Unknown value for regs.DCOR.tmplMode');
        end
        assert(max(tmplIndex(:))<=63);
    end
    
%     lgr.print2file(sprintf('\ttmplIndex = %X\n',tmplIndex(lgrOutPixIndx)));
    
    
    

    
    if (regs.DCOR.outIRnest)
        iImgRAW = pflow.aImg;
    elseif (regs.DCOR.outIRcma)
        outIRcmaBin = uint16(regs.DCOR.outIRcmaIndex(1))*84+uint16(regs.DCOR.outIRcmaIndex(2)); %%CHECK
        cmaBin = min(outIRcmaBin+1, size(cma_, 1));
        iImgRAW = uint16(permute(cma_(cmaBin,:,:),[2 3 1]));
    end
    
    cma_dec = reshape(cma_, downSamplingR, double(regs.GNRL.tmplLength)/downSamplingR, regs.GNRL.imgVsize, regs.GNRL.imgHsize);
    
    cma_dec = permute(sum(uint32(cma_dec),1, 'native'),[2 3 4 1]);
    
    
%     lgr.print2file(sprintf('\tcma_dec = %s\n',sprintf('%08X ',flipud(cma_dec(:,lgrOutPixIndx)))));
    
    
    kerC = tmplC(1:nC,:);
    kerF = tmplF(1:nF,:);
    
    
    cor_dec = Utils.correlator(uint16(cma_dec), kerC, uint32(tmplIndex));
    
%     lgr.print2file(sprintf('\tcor_dec = %s\n',sprintf('%08X ',flipud(cor_dec(:,lgrOutPixIndx)))));
    
    %% coarse masking - for crosstalk and other
    %since 000 is the LSB(bin 3), it needs to set 1Ghz (thus need to inverse txmode:
    %txmode=0 --> 1Ghz --> reg(1)
    %txmode=1 --> 0.5Ghz --> reg(2)
    %txmode=2 --> 0.25Ghz --> reg(3)
    txmode = bitand(bitshift(pflow.pipeFlags,-1),uint8(3))+1;
    
    
    txmode(txmode==4)=3;%mix mode flags
    
    cMask = regs.DCOR.coarseMasking;
    cMask = reshape(cMask,[],3).';
    
    %cut to wanted size
    cMask = cMask(:,1:size(cor_dec,1)).';
    
    % due to DCOR HW implementation the registers should be stored in
    % decending order while the first (0) bin is in the last place
    cMask = flipud(cMask);
    cMask = circshift(cMask,[1 0]);
    
    
    maskMat = zeros(size(cor_dec,1),size(cor_dec,2)*size(cor_dec,3),'uint32');
    maskMat(:,1:numel(txmode)) = cMask(:,txmode(:));
    maskMat = reshape(maskMat,size(cor_dec));
    
    cor_dec_masked = cor_dec.*uint32(maskMat);
    [~, maxIndDec] = max(cor_dec_masked);
%     lgr.print2file(sprintf('\tmaxIndDec = %X\n',maxIndDec(lgrOutPixIndx)));
    %%
    %%% tamplate read a = reshape(hex2dec(vec(dec2hex(luts.DCOR.tamplate1(:)).')),64,[]);
    
    corrOffset = uint8(maxIndDec-1);
    corrOffset = permute(corrOffset,[2 3 1]);
    
    %calc correlation segment
    corrSegment = Utils.correlator(cma_, kerF, uint32(tmplIndex), uint16(corrOffset)*uint16(downSamplingR), regs.DCOR.fineCorrRange);
    
    %correlation segment size is always 33
    n = 16-regs.DCOR.fineCorrRange;
    zp = uint32(zeros(n,regs.GNRL.imgVsize,regs.GNRL.imgHsize));
    corrSegment = [zp;corrSegment;zp];
    
%     lgr.print2file(sprintf('\tcorrSegment = %s\n',sprintf('%08X ',flipud(corrSegment(:,lgrOutPixIndx)))));
%     lgr.print2file(sprintf('\tcorrOffset = %02X\n',corrOffset(lgrOutPixIndx)));
    
    
    %normalize
    % corrSegment = bsxfun(@minus,int32(2*corrSegment),int32(sum(cma)));
    % nfactor = corNorm*2/(length(template)*double(intmax(class(cma))));
    % corrSegment = int32(double(corrSegment)*nfactor);
    
    
    
    
    
    
    
    %calculate maxSideLobe
    % winsz = cfs;
    % [yg,xg]=ndgrid(1:sc2,1:sc3);
    % for l =-winsz:winsz
    %     maxclni=mod(squeeze(maxIndDec)-l-1,size(corrDec,1))+1;
    %     ind = sub2ind(size(corrDec),maxclni,yg,xg);
    %     corrDec(ind(:))=0;
    % end
    % mxSideLobe=max(corrDec);
    %normalize
    % mxSideLobe =  int32(2*mxSideLobe)-int32(sum(cmaDec));
    % nfactorDec = corNorm*2/(length(templateDec)*double(intmax(class(cma))));
    % mxSideLobe = permute(uint16(double(mxSideLobe)*nfactorDec),[2 3 1]);
    
    % logger
    
    
end % bypass

%% TRACER
if(~isempty(traceOutDir) )
    [py,px]=ind2sub([regs.GNRL.imgVsize regs.GNRL.imgHsize ],pflow.pixIndOutOrder);
    
    pxOut=int16([px,py]'-1);
    % DCOR_out
    outTxt = [...
        Utils.toHex(corrSegment, pxOut, 6, 33);...
        Utils.toHex(corrOffset, pxOut, 2);...
        Utils.toHex(iImgRAW, pxOut, 3);...
        Utils.toHex(pxOut(1,:), 3);...
        Utils.toHex(pxOut(2,:), 3);...
        Utils.toHex(pflow.dutyCycle, pxOut, 1);...
        Utils.toHex(psnr_value, pxOut, 2)...
        ];
    Utils.buildTracer(outTxt,'DCOR_out',traceOutDir);
    clear outTxt;
    
    Utils.buildTracer(Utils.toHex(pflow.pipeFlags,pxOut,1),'DCOR_flags',traceOutDir);
    
    % cma_dec 11bit
    outTxt = Utils.toHex(cma_dec, pxOut, 3, 256);
    Utils.buildTracer(outTxt,'DCOR_cma_dec',traceOutDir);
    clear outTxt;
    
    % corr_dec 11bit
    outTxt = Utils.toHex(cor_dec_masked, pxOut, 6, 256);
    Utils.buildTracer(outTxt,'DCOR_cor_dec',traceOutDir);
    clear outTxt;
    
    tmpl_psnr_txt = [ Utils.toHex(psnr_value, pxOut, 2); Utils.toHex(tmplIndex, pxOut, 2) ];
    Utils.buildTracer(tmpl_psnr_txt,'DCOR_tmpl_psnr',traceOutDir);
    
    %% template LUT trace
    Utils.buildTracer(Utils.mat2hex(tmplF',1),'DCOR_fineTemplates',traceOutDir);
    Utils.buildTracer(Utils.mat2hex(tmplC',1),'DCOR_coarseTemplates',traceOutDir);
    
end

% lgr.print2file('\n\t----- end DCOR -----\n');

end