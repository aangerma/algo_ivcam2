fw = Pipe.loadFirmware('C:\source\algo_ivcam2\+Calibration\initScript');
[regs,luts] = fw.get();
[cma,cmaSTD] = readCMA(hw);
% cma = uint8(255*(-1+randi(2,416,480,640)));
%%
pflow.cma = cma/2;
assert(max(pflow.cma(:))<128); %cma should be always 7b
cma_ = min(63, bitshift(pflow.cma+1,-1));

nF = double(regs.GNRL.tmplLength);
nC = double(regs.DCOR.coarseTmplLength);

uint82uint4 = @(v) vec([bitand(v(:),uint8(15)) bitshift(v(:),-4)]');
mem2tbl = @(v) reshape(flipud(reshape(uint82uint4 (typecast(v,'uint8')),8,[])),[],64);
tmplC = mem2tbl (luts.DCOR.tmpltCrse);
tmplF = mem2tbl (luts.DCOR.tmpltFine);
tmplF  = circshift(tmplF ,[-nF+16,16]);

downSamplingR = 2 ^ double(regs.DCOR.decRatio);
tmplIndex = zeros(480,640);
cma_dec = reshape(cma_, downSamplingR, double(regs.GNRL.tmplLength)/downSamplingR, regs.GNRL.imgVsize, regs.GNRL.imgHsize);
cma_dec = permute(sum(uint32(cma_dec),1, 'native'),[2 3 4 1]);

kerC = tmplC(256-nC+1:256,:);
kerF = tmplF(1024-nF+1:1024,:);
kerC =flipud(kerC);%ASIC ALIGNMENT
kerF =flipud(kerF);%ASIC ALIGNMENT

cor_dec = Utils.correlator(uint16(cma_dec), kerC, uint32(tmplIndex));
cor_dec_masked = cor_dec;
[~, maxIndDec] = max(cor_dec_masked);

corrOffset = uint8(maxIndDec-1);
corrOffset = permute(corrOffset,[2 3 1]);

%calc correlation segment
corrSegment = Utils.correlator(cma_, kerF, uint32(tmplIndex), uint16(corrOffset)*uint16(downSamplingR), regs.DCOR.fineCorrRange);

%correlation segment size is always 33
n = 16-regs.DCOR.fineCorrRange;
zp = uint32(zeros(n,regs.GNRL.imgVsize,regs.GNRL.imgHsize));
corrSegment = [zp;corrSegment;zp];

pflow.corrOffset = corrOffset;
pflow.corr = corrSegment;


mxv=64;
ker = @(sr) ([sr;mxv-2*sr;sr]);

cor_seg_fil = pflow.corr;
cor_seg_fil=(pad_array(cor_seg_fil,4,0,'both'));
cor_seg_fil = bitshift(convn(cor_seg_fil, ker( regs.DEST.smoothKerLen(1)), 'valid'),-6);
cor_seg_fil = bitshift(convn(cor_seg_fil, ker( regs.DEST.smoothKerLen(2)), 'valid'),-6);
cor_seg_fil = bitshift(convn(cor_seg_fil, ker( regs.DEST.smoothKerLen(3)), 'valid'),-6);
cor_seg_fil = bitshift(convn(cor_seg_fil, ker( regs.DEST.smoothKerLen(4)), 'valid'),-6);
cor_seg_fil = uint32(cor_seg_fil);


corrOffset=pflow.corrOffset; %zero based
corrOffset = uint16(corrOffset)*uint16( 2 ^ double(regs.DEST.decRatio));


corrOffset = uint16(mod(int32(corrOffset)-int32(regs.DEST.fineCorrRange)  ,int32(regs.GNRL.tmplLength)));

corrOffset = single(corrOffset)-1 ;

%     lgr.print2file(sprintf('\tcor_seg_fil=%s\n',sprintf('%08X ',flipud(cor_seg_fil(:,lgrOutPixIndx)))));
%     lgr.print2file(sprintf('\tcorrOffset(fine) = %02X\n',pflow.corrOffset(lgrOutPixIndx)));

[peak_index, peak_val ] = Pipe.DEST.detectPeaks(cor_seg_fil,corrOffset,regs.MTLB.fastApprox(2));
maxPeakMaxVal = (2^6-1);%hard coded
peak_val_norm  = uint8(min(maxPeakMaxVal,bitshift(peak_val*regs.DEST.maxvalDiv,-14)-regs.DEST.maxvalSub));
figure, imagesc(peak_val_norm,[0,63]); colorbar;
figure, histogram(peak_val_norm)
%% confidence
% confOut = Pipe.DEST.confBlock(pflow.dutyCycle,pflow.psnr,peak_val_norm,pflow.iImgRAW, regs);