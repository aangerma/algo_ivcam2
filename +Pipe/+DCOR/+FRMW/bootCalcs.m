function [regs,autogenRegs,autogenLuts] = bootCalcs(regs,luts,autogenRegs,autogenLuts)

autogenRegs.DCOR.yScaler = uint8(zeros(128,1)); %it's uint4
autogenRegs.DCOR.decRatio = uint8(log2(double(regs.GNRL.sampleRate)/double(regs.FRMW.coarseSampleRate)));
autogenRegs.DEST.decRatio = autogenRegs.DCOR.decRatio;

autogenRegs.DCOR.outIRcmaIndex = uint8([floor(double(regs.FRMW.outIRcmaBin)/84) mod(regs.FRMW.outIRcmaBin,84)]);

autogenRegs.DCOR.yScalerDivExp = uint8(ceil(log2(double(regs.GNRL.imgVsize)))-7);
downSamplingR = 2 ^ double(autogenRegs.DCOR.decRatio);
autogenRegs.DCOR.coarseTmplLength = uint16(double(regs.GNRL.codeLength)*double(regs.GNRL.sampleRate)/downSamplingR);



%% coarse masking
pdSampleOffsetFine = (regs.DEST.txFRQpd./regs.DEST.sampleDist); %ofsset caused by pd [mm]/ offset caused by pd [mm/sample] -> [sample]
pdSampleOffsetCoarse = uint8(floor(pdSampleOffsetFine/(downSamplingR)+0.5));

maskLength = double(regs.GNRL.tmplLength)/downSamplingR;

coarseMasking = repmat(regs.FRMW.coarseMasking,3,1).';
for i=1:3
    coarseMasking(1:maskLength,i) = circshift(coarseMasking(1:maskLength,i),pdSampleOffsetCoarse(i));
    coarseMasking(1:maskLength,i) = circshift(coarseMasking(1:maskLength,i),-1);%due to HW implementation
end
autogenRegs.DCOR.coarseMasking = coarseMasking(:).';

 %% templates

codevec = vec(fliplr(dec2bin(regs.FRMW.txCode(:),32))')=='1';
codevec = codevec(1:regs.GNRL.codeLength);

codevec =flipud(codevec);%ASIC ALIGNMENT

kF = double(vec(repmat(codevec,1,regs.GNRL.sampleRate)'));
nF =  length(kF)  ; 
nC =  bitshift(nF,-double(autogenRegs.DCOR.decRatio));
nTemplates = iff(nF==2048,32,64);

[bF,aF] = butter_(1,.99);
templates = (zeros(nF,64));
for i=1:nTemplates 
    templates(:,i)=kF;
    kF=filtfilt_(bF,aF,kF);
end

templates = uint8(round(min(1,max(0,templates))*7));
tbl2uint32 = @(t) typecast(vec(flipud(reshape(uint8(sum(bsxfun(@bitshift,reshape(t(:),2,[]),[4;0]))),4,[]))),'uint32');
%% gen fine
tmplF = templates;
% replicate to 1024
tmplF = tmplF(mod(0:1023,nF)+1,:);
tmplF  = circshift(tmplF ,[nF-16,-16]);
if(all(luts.DCOR.tmpltFine==0))%already set using aux file, do not set!
    autogenLuts.DCOR.tmpltFine = tbl2uint32(tmplF);
end
%% gen coarse

%corse from fine
tmplC=bitshift(uint8(permute(sum(reshape(templates,downSamplingR,[],size(templates,2))),[2 3 1])),-double(autogenRegs.DCOR.decRatio));
% replicate to 256
tmplC = tmplC(mod(0:255,nC)+1,:);
if(all(luts.DCOR.tmpltCrse==0))%already set using aux file, do not set!
    autogenLuts.DCOR.tmpltCrse = tbl2uint32(tmplC);
end
%% PSNR
% this should be calculated offline (not firmware)
% psnrRegs = Pipe.DCOR.FRMW.genPSNRregs();
% autogenRegs = Firmware.mergeRegs(autogenRegs,psnrRegs);
%% ASIC
crse_len  = double(regs.GNRL.tmplLength)/downSamplingR;
autogenRegs.DCOR.loopCtrl=...
    bitshift(uint32(uint8(ceil(crse_len / 66.0 ))),0)+...
    bitshift(uint32(uint8(ceil(crse_len / 22.0 ))),8)+...
    bitshift(uint32(uint8(ceil(double(regs.GNRL.tmplLength) / 84.0 ))),16);

%%
regs = Firmware.mergeRegs(regs,autogenRegs);


end

