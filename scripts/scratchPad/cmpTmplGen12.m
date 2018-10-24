function cmpTmplGen12()
fw = Firmware;
fw.get();

regs.GNRL.codeLength = uint8(16);
regs.GNRL.sampleRate = uint8(8);
regs.FRMW.coarseSampleRate = uint8(2);
fw.setRegs(regs,'');
[regs, luts] = fw.get();

lut1 = bootCalc1(regs);
lut2 = bootCalc2(regs);


end
function [autogenLuts] = bootCalc1(regs)
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
tmplF = circshift(tmplF,[mod(1024,nF),0]);
tmplF(1:mod(1024,nF),:) = tmplF(end-mod(1024,nF)+1:end,:);

tmplF  = circshift(tmplF ,[(nF-16),0]);
if(~regs.FRMW.dcorTemplatesFromFile || all(luts.DCOR.tmpltFine==0))%already set using aux file, do not set!
    autogenLuts.DCOR.tmpltFine = tbl2uint32(tmplF);
end
%% gen coarse

%corse from fine
tmplC=bitshift(uint8(permute(sum(reshape(templates,downSamplingR,[],size(templates,2))),[2 3 1])),-double(autogenRegs.DCOR.decRatio));
% replicate to 256
tmplC = tmplC(mod(0:255,nC)+1,:);
tmplC = circshift(tmplC,[mod(256,nC),0]);
tmplC(1:mod(256,nC),:) = tmplC(end-mod(256,nC)+1:end,:);
if(~regs.FRMW.dcorTemplatesFromFile || all(luts.DCOR.tmpltCrse==0))%already set using aux file, do not set!
    autogenLuts.DCOR.tmpltCrse = tbl2uint32(tmplC);
end
end
function [autogenLuts] = bootCalc2(regs)

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
autogenLuts.DCOR.tmpltFine = tbl2uint32(tmplF);

%% gen coarse

%corse from fine
tmplC=bitshift(uint8(permute(sum(reshape(templates,downSamplingR,[],size(templates,2))),[2 3 1])),-double(autogenRegs.DCOR.decRatio));
% replicate to 256
tmplC = tmplC(mod(0:255,nC)+1,:);
autogenLuts.DCOR.tmpltCrse = tbl2uint32(tmplC);

end