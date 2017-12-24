function [ cmaOut, irOut, nestOut, dutyCycle, flagsOut,pixIndOutOrder,pixRastOutTime, reports] = RAST( inData, pipeData, regs, ~, lgr,traceOutDir)


lgr.print2file('\n\t------- RAST -------\n');

xy = pipeData.xyPix;

flags = inData.flags;
roi = uint8(pipeData.roiFlag);
flags = bitor(flags, bitshift(roi, 5));

mRegs = regs.RAST;

mRegs.sampleRate = regs.GNRL.sampleRate;
mRegs.codeLength = regs.GNRL.codeLength;
mRegs.sideLobeDir= regs.GNRL.sideLobeDir;
mRegs.imgHsize = regs.GNRL.imgHsize;
mRegs.imgVsize = regs.GNRL.imgVsize;
mRegs.rangeFinder = regs.GNRL.rangeFinder;
mRegs.fastApprox=regs.MTLB.fastApprox(1);
mRegs.chunkExp = 6; % chunk size is 64
mRegs.extraResExp = 2;
mRegs.chunkRate = int32(round(regs.MTLB.txSymbolLength)) * 16 / int32(regs.GNRL.sampleRate);

yScanConsist = [0 diff(double(xy(2,:))).*(double(bitand(flags(2:end), 4))-2)];
yNonMonoPos = find(all(xy>=0 & bsxfun(@lt,xy,[regs.GNRL.imgHsize*4;regs.GNRL.imgVsize]) ) & yScanConsist<0);
%assert(isempty(find(yScanConsist < 0,1)), 'failed: y is non-monotonic along scan');
if (~isempty(yNonMonoPos))
    
    errTxt='failed: y is non-monotonic at the scan edges';
    lgr.print2file('\t*** %s ***\n',errTxt);
    
    if(regs.MTLB.debug)
        figure(23324)
        plot(xy(1,:)/4,xy(2,:),xy(1,yNonMonoPos)/4,xy(2,yNonMonoPos),'.','markersize',30);
        rectangle('position',[0 0 regs.GNRL.imgHsize-1 regs.GNRL.imgVsize-1])
    end
    if(regs.MTLB.assertionStop)
        error(errTxt);
    end
    %figure(7737); imagesc(conv2(double(irC ~= 0), ones(3)/9,'same')<0.3);
end

reports = struct();


R0 = 1;
R1 = length(inData.slow); % 20000; 
R = R0:R1;
Rch = ((R0-1)*64+1):(R1*64);

pcqIn.fast = uint8(inData.fast(Rch));
pcqIn.ir = inData.slow(R);
pcqIn.xy = xy(:,R);
pcqIn.nest = pipeData.nest(R);
pcqIn.flags = flags(R);

[pcqOut, pcqStats] = Pipe.RAST.PCQ(pcqIn, mRegs);
reports.pcq = pcqStats;

assert(max([0;pcqOut.chunks(:)]) <= 1, 'failed: Binary samples');

if (pcqStats.consecutiveChunksFail)
    errTxt = 'PCQ failed: non-consecutive (garbage) chunks used';
    if (regs.MTLB.assertionStop)
        error(errTxt);
    else
        warning('pipe:RAST',errTxt);
    end
end

mRegs.nScansPerPixel = uint8(4);

[cmacOut, cmacStats] = Pipe.RAST.CMAC(pcqOut, mRegs);

nestOut = cmacOut.nest;

reports.cmac = cmacStats;
assert(max(cmacOut.cmaA(:)) <= regs.RAST.cmaMaxSamples, 'failed: cma max samples in CMAC');
assert(max(cmacOut.cmaC(:)) <= regs.RAST.cmaMaxSamples, 'failed: cma max samples in CMAC');

% % logger
% if numel(pcqChunks) ~= 0
%     lgr.print2file('\tPCQ - chunk number %d\n',regs.MTLB.loggerChunkIndex);
%     lgrChunkIndx = [];
%     if regs.MTLB.loggerChunkIndex < length(pcqStats.valids(:)) % ALL chuncks (not only valid)
%         lgrChunkIndx = pcqStats.validIndices(regs.MTLB.loggerChunkIndex + 1) + 1;
%         % Ignore invalid chuncks
%         lgrChunkIndx(lgrChunkIndx == -1) = [];
%     end
%     
%     pcqOffset_ = uint8([0 bitshift(pcqOffset,-3)]);
%     
%     lgr.print2file(['\t\tpcqXY (x, y) = %03X, %03X\n\t\tpcqChunks = %s\n\t\tpcqOffset = %02X',...
%         '\n\t\tpcqIR = %03X\n\t\tpcqNest = %03X\n\t\tpcqFlags = %1X\n\n'],...
%         pcqXY(1,lgrChunkIndx),pcqXY(2,lgrChunkIndx),...
%         logical2hex(logical(pcqChunks(:,lgrChunkIndx))),pcqOffset_(lgrChunkIndx),...
%         pcqIR(lgrChunkIndx),pcqNest(lgrChunkIndx),pcqFlags(lgrChunkIndx));
% end


pxIndCmac = sub2ind([mRegs.imgVsize,mRegs.imgHsize],cmacOut.xy(2,:)+1,cmacOut.xy(1,:)+1)';
if(length(pxIndCmac)~=length(unique(pxIndCmac)))
    upixindOut=unique(pxIndCmac);
    [bady,badx] = ind2sub([mRegs.imgVsize,mRegs.imgHsize],upixindOut(find(histc(pxIndCmac,upixindOut)~=1)));
    warning('CMAC output is not monotonic. CMA with coordinates <%d,%d> arrives twice',badx-1,bady-1);
end

%% timestams analysis
%{
ts = timestampsCmac;
tsWoZeros = ts;
tsWoZeros(ts == 0) = uint32(2^31);
tColMax = double(max(ts))*4/25000; % in col time
tColMin = double(min(tsWoZeros))*4/25000; % in col time
figure; plot(tColMax - tColMin);
%}

%% IR

if (regs.MTLB.fastApprox(1))
    irCinv = 1./single(cmacOut.irC);
else
    irCinv = Utils.fp32('inv',single(irC));
end

ir = single(cmacOut.irA).*irCinv;
irVar = cmacOut.irMax - cmacOut.irMin;

ir(cmacOut.irC == 0) = 0;
irVar(cmacOut.irC == 0) = 0;

ir = min(uint16(ir), 2^12-1);
irVar = min(uint16(irVar), 2^12-1);

if (regs.RAST.outIRvar)
    irCmac = irVar;
else
    irCmac = ir;
end


% mLuts.divCma = regs.RAST.divCma;
% HARD CODED
%mLuts.divCma = uint8([0 255 127 85 63 51 42 36 31 28 25 23 21 19 18 17 15 15 14 13 12 12 11 11 10 10 9 9 9 8 8 8 7 7 7 7 7 6 6 6 6 6 6 5 5 5 5 5 5 5 5 5 4 4 4 4 4 4 4 4 4 4 4 4 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2]);
mLuts.divCma = uint8([0  127   64   42   32   25   21   18   16   14   13   12   11   10    9    8    8    7    7    7    6    6    6    6    5    5    5    5    5    4    4    4]);
mLuts.biltAdaptR = regs.RAST.biltAdaptR;
mLuts.biltSigmoid = regs.RAST.biltSigmoid;
mLuts.biltSpat = regs.RAST.biltSpat; %YC: TODO uint4!!!

mRegs.fastApprox = regs.MTLB.fastApprox(1);

%cmaPx = cmaA.*mLuts.divCma(cmaC+1);
cmaPx = Pipe.RAST.cmaNorm(cmacOut.cmaA, cmacOut.cmaC, cmacOut.xy, mLuts);

assert(max(cmaPx(:))<128); %normalizer outputs 7b

[cmaOut, irMM, flagsOut, pxOut, si, fStats, cmafWin] = Pipe.RAST.cmaFilter(cmaPx, irCmac, cmacOut.flags, cmacOut.timestamp, cmacOut.xy, mRegs, mLuts);
reports.filter = fStats;
reports.filterWin = cmafWin;
cmafWin.xy = reshape(cmafWin.xy, 2, 9, []);
%assert(all((sum(cmafWin.w)==256)));
assert(max(cmaOut(:))<128);

assert(max(cmaPx(:))<128); %rast outputs 7b

% confDC computation
confSum = reshape(sum(uint32(cmaOut), 1, 'native'), size(ir));

dcCodeNorm = uint64(regs.RAST.dcCodeNorm); %dcCodeNorm = uint64(single(2^22)/single(K))

imgTxRx = bitand(bitshift(flagsOut, -1), 3);
invalidTxRx = (imgTxRx == 3);
imgTxRx(invalidTxRx) = 0;
dcLevel = int16(mRegs.dcLevel);
imgDcLevel = map(dcLevel, imgTxRx+1);

diffDC = min(63, abs(int16(bitshift((uint64(confSum)*dcCodeNorm), -22))-imgDcLevel));
%diffDC(confSum == 0) = 63;

%lutConf = round((-tanh(((0:63)-6)/4.2)+1)*8.0);
%lutConf = min(uint8(lutConf), 15);
lutConf = regs.RAST.confDC;

%confDC = uint8(15-min(15, bitshift(diffDC, -1)));
confDC = map(lutConf, diffDC+1);
confDC(invalidTxRx) = 0;

dutyCycle = confDC;

if (regs.RAST.outIRmm)
    irOut = irMM;
else
    irOut = irCmac;
end

%{
%zeroInd = (cmaC == 0);
%cmaC(zeroInd) = 1;
cmaF = cmaA.*mLuts.divCma(cmaC+1);
cma(zeroInd) = 0;
%cma = uint8(double(cmaA)./double(cmaC)*255);
%}

pxindOut  = sub2ind([mRegs.imgVsize,mRegs.imgHsize],pxOut(2,:)+1,pxOut(1,:)+1)';
if(length(pxindOut)~=length(unique(pxindOut)))
    upixindOut=unique(pxindOut);
    [bady,badx] = ind2sub([mRegs.imgVsize,1:mRegs.imgHsize],upixindOut(find(histc(pxindOut,upixindOut)~=1,1)));
    warning('CMA output is not monotonic. CMA with coordinates <%d,%d> arrives twice',badx-1,bady-1);
end
 pixoutMat = accumarray(pxindOut,(1:size(pxOut,2))',[uint32(mRegs.imgVsize)*uint32(mRegs.imgHsize) 1],@(v) v(end),nan);
 pixoutMat=reshape(pixoutMat,[mRegs.imgVsize mRegs.imgHsize]);
 [~,pixIndOutOrder] = sort(pixoutMat(:));
 pixIndOutOrder=pixIndOutOrder(1:numel(pixoutMat)-sum(isnan(pixoutMat(:))));

pixRastOutTime = double(fStats.timestamps)*1000/double(regs.MTLB.asicRASTclock);

% pixIndOutOrder=pxindOut;
% lgrOutPixIndx = [];
% if ~isempty(pixIndOutOrder) && regs.MTLB.loggerOutPixelIndex < length(pixIndOutOrder)
%     lgrOutPixIndx = pixIndOutOrder(regs.MTLB.loggerOutPixelIndex+1);
% end

% 
% if ~isempty(lgrOutPixIndx)
%     
%     if lgrOutPixIndx <= size(pxOutCmac,2)
%         
%         % CMAC logger
%         pxOutCmacTmp = pxOutCmac + repmat(int16(1),size(pxOutCmac));
%         pxOutCmacIdx = sub2ind([size(cmaA,2),size(cmaA,3)],pxOutCmacTmp(2,:),pxOutCmacTmp(1,:));
%         
%         lgr.print2file('\tCMAC - pixel = %d\n',lgrOutPixIndx);
%         lgr.print2file('\t\tpxOutCmac (x, y) = %03X, %03X\n',...
%             pxOutCmac(1,lgrOutPixIndx),pxOutCmac(2,lgrOutPixIndx));
%         lgr.print2file('\t\tFirst 8 cmaA bins (bin0,...bin7): %s\n\t\tcmaC = %02X\n',...
%             reshape([dec2hexFast(cmaA(1:8,pxOutCmacIdx(lgrOutPixIndx)),2),repmat(' ',8,1)]',3*8,[])',...
%             cmaC(lgrOutPixIndx));
%         lgr.print2file('\t\tflagsCmac = %01X\n\t\tir = %03X\n\t\tnestOut = %03X\n\n',...
%             flagsCmac(pxOutCmacIdx(lgrOutPixIndx)),irCmac(pxOutCmacIdx(lgrOutPixIndx)),...
%             nestOut(pxOutCmacIdx(lgrOutPixIndx)));
%         
%         % cmaFilter logger
%         lgr.print2file('\tCMA filter\n');
%         lgr.print2file(sprintf('\t\tcma = %s\n',sprintf('%08X ',flipud(cmaOut(:,lgrOutPixIndx)))));
%         lgr.print2file(sprintf('\t\tir = %X\n',irOut(lgrOutPixIndx)));
%         lgr.print2file(sprintf('\t\tnestOut = %X\n',nestOut(lgrOutPixIndx)));
%         
%         
%         if (~regs.RAST.biltBypass)
%             lgr.print2file('\t\tcmafWin.xy (x0,y0,...x8,y8) = %s\n\n',...
%                 reshape([dec2hexFast(cmafWin.xy(1,:,lgrOutPixIndx), 3),repmat(' ',9,1)]',4*9,[])');
%         end
%     end
% end


if(regs.MTLB.debug)
    % CMA filter weight viz
    figure(443322);
    wImg = zeros(size(irMM),'uint16');
    wImg(pxindOut) = squeeze(cmafWin.w(5,:));
    imagesc(wImg);
    title('CMA filters weights')
    figure(443323)
    imagesc(reshape(statsCmac.xLate,size(irMM)));
    title('X late chunks (CMAC output)');
    axis image
    colorbar
    
end

lgr.print2file('\t Scan loop holes lost chunks: %.2f%%\n',(length(pcqOut.ir)-sum(cmacOut.cmaC(:))/64)/length(pcqOut.ir)*100);

if(~isempty(traceOutDir) )
    %% RAST trace
    outTxt = [...
        Utils.toHex(flagsOut, pxOut, 1);...
        Utils.toHex(pxOut(1,:), 3); Utils.toHex(pxOut(2,:), 3);...
        Utils.toHex(irOut, pxOut, 3); Utils.toHex(nestOut, pxOut, 3);...
        Utils.toHex(dutyCycle, pxOut, 1);...
        Utils.toHex(cmaOut, pxOut, 4096)];
    Utils.buildTracer(outTxt,'RAST_out',traceOutDir);
    clear outTxt
    
    %% CMAC trace
    if (regs.GNRL.rangeFinder && size(cmaOut,1) > 1024)
        outTxt0 = [...
            Utils.toHex(flagsCmac, cmacOut.xy, 1);...
            Utils.toHex(cmacOut.xy(1,:), 3); Utils.toHex(cmacOut.xy(2,:), 3);...
            Utils.toHex(irCmac, cmacOut.xy, 3); Utils.toHex(nestOut, cmacOut.xy, 3);...
            Utils.toHex(cmacOut.cmaA(1:1024,:,:), cmacOut.xy, 2048);...
            Utils.toHex(cmacOut.cmaC(1:8:end,:,:), cmacOut.xy, 256)];
        outTxt1 = [...
            Utils.toHex(flagsCmac, cmacOut.xy, 1);...
            Utils.toHex(cmacOut.xy(1,:), 3); Utils.toHex(cmacOut.xy(2,:), 3);...
            Utils.toHex(irCmac, cmacOut.xy, 3); Utils.toHex(nestOut, cmacOut.xy, 3);...
            Utils.toHex(cmacOut.cmaA(1025:end,:,:), cmacOut.xy, 2048);...
            Utils.toHex(cmacOut.cmaC(1025:8:end,:,:), cmacOut.xy, 256)];
        outTxt = [outTxt0(:,1) outTxt1(:,1) outTxt0(:,2) outTxt1(:,2)];
    else
        outTxt = [...
            Utils.toHex(cmacOut.flags, cmacOut.xy, 1);...
            Utils.toHex(cmacOut.xy(1,:), 3); Utils.toHex(cmacOut.xy(2,:), 3);...
            Utils.toHex(irCmac, cmacOut.xy, 3); Utils.toHex(nestOut, cmacOut.xy, 3);...
            Utils.toHex(cmacOut.cmaA, cmacOut.xy, 2048);...
            Utils.toHex(cmacOut.cmaC(1:8:end,:,:), cmacOut.xy, 256)];
    end
    Utils.buildTracer(outTxt,'RAST_cmac',traceOutDir);
    clear outTxt
    
    %% PCQ out traces
    pcqChunks64 = logical2uint64(pcqOut.chunks);
    pcqOffs = uint8(bitshift(pcqOut.offset,-3));
    ind1 = pcqStats.validIndices(1,:);
    ind2 = pcqStats.validIndices(2,:);
    ind3 = pcqStats.validIndices(3,:);
    ind4 = pcqStats.validIndices(4,:);
    outTxt = [...
        Utils.toHex(pcqOut.xy(1,:), ind1, 3);...
        Utils.toHex(pcqOut.xy(2,:), ind1, 3);...
        Utils.toHex(pcqOut.nest, ind1, 3);...
        Utils.toHex(pcqOut.flags, ind1, 1);...
        Utils.toHex(pcqOffs, ind1, 2);...
        Utils.toHex(pcqOut.ir, ind1, 3);...
        Utils.toHex(pcqChunks64, ind1, 16);...
        Utils.toHex(pcqOffs, ind2, 2);...
        Utils.toHex(pcqOut.ir, ind2, 3);...
        Utils.toHex(pcqChunks64, ind2, 16);...
        Utils.toHex(pcqOffs, ind3, 2);...
        Utils.toHex(pcqOut.ir, ind3, 3);...
        Utils.toHex(pcqChunks64, ind3, 16);...
        Utils.toHex(pcqOffs, ind4, 2);...
        Utils.toHex(pcqOut.ir, ind4, 3);...
        Utils.toHex(pcqChunks64, ind4, 16)...
        ];
    Utils.buildTracer(outTxt,'RAST_pcq',traceOutDir);
    clear outTxt
    
    %% RAST_BLF_input trace
    if (~regs.RAST.biltBypass)
        cmafXY = reshape(cmafWin.xy, 2,[]);
        valids = (cmafXY(1,:)>-1);
        outTxt = [...
            Utils.toHex(valids, 1);...
            Utils.toHex(cmacOut.flags, cmafXY, 1);...
            Utils.toHex(cmafXY(1,:), 3);...
            Utils.toHex(cmafXY(2,:), 3);...
            Utils.toHex(irCmac, cmafXY, 3);...
            Utils.toHex(nestOut, cmafXY, 3);...
            Utils.toHex(cmaPx, cmafXY, 2048)];
        Utils.buildTracer(outTxt,'RAST_BLF_input',traceOutDir);
        clear outTxt
        
        %% RAST BLF intermediate traces
        blfTextW = reshape(dec2hexFast(cmafWin.w, 2)',2*9,[])';
        blfTextWr = reshape(dec2hexFast(cmafWin.wr, 2)',2*9,[])';
        blfTextIRSort = reshape(dec2hexFast(cmafWin.irSort, 3)',3*10,[])';
        blfTextRowPtrs = reshape(dec2hexFast(cmafWin.rowPtrs, 1)',3,[])';
        blfTextXY = reshape(dec2hexFast(cmafWin.xy, 3)',6*9,[])';
        
        Utils.buildTracer(blfTextW,'RAST_BLF_W',traceOutDir);
        Utils.buildTracer(blfTextWr,'RAST_BLF_Wr',traceOutDir);
        Utils.buildTracer(blfTextIRSort,'RAST_BLF_IRSort',traceOutDir);
        Utils.buildTracer([blfTextRowPtrs blfTextXY],'RAST_BLF_RowXY',traceOutDir);
    end
    
    %% RAST PCQ Pixel FIFO
    pcqTextPxs = reshape(dec2hexFast(pcqStats.pxInfo, 3)',3*8,[])';
    Utils.buildTracer(pcqTextPxs,'RAST_PCQ_PXFIFO',traceOutDir);
    
end


% assert(~any(vec(permute(any(cma,1),[2 3 1]) & irOut==0)),'IR is zero with full CMA?');
% if ~isempty(lgr)
lgr.print2file('\t----- end RAST -----\n');
% end

end

