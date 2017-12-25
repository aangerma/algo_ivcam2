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

kF = double(vec(repmat(codevec(1:regs.GNRL.codeLength),1,regs.GNRL.sampleRate)'));
n =  length(kF)  ; 


[bF,aF] = butter_(3,.12);
bF=1;aF=1; %set all templates to the same values
templates = (zeros(n,64));
for i=1:64
    templates(:,i)=kF;
    kF=filtfilt_(bF,aF,kF);
end

templates = uint8(round(min(1,max(0,templates))*7));
fineLen = size(templates, 1);
%%
%corse from fine
decTemplates=bitshift(uint8(permute(sum(reshape(templates,downSamplingR,[],size(templates,2))),[2 3 1])),-double(autogenRegs.DCOR.decRatio));
decLen = size(decTemplates, 1);

if (regs.GNRL.rangeFinder)
    tSize = [2048 32];
    cSize = [512 32];
else
    tSize = [1024 64];
    cSize = [256 64];
end

fineReps = floor(tSize(1)/fineLen);
templates = repmat(templates, [fineReps 1]);

decReps = floor(cSize(1)/decLen);
decTemplates = repmat(decTemplates, [decReps 1]);

fineTemplates = zeros(tSize, 'uint8');
coarseTemplates = zeros(cSize, 'uint8');

if (regs.GNRL.rangeFinder)
    fineTemplates(1:size(templates,1),:) = templates(:,1:2:end);
    coarseTemplates(1:size(decTemplates,1),:) = decTemplates(:,1:2:end);
else
    fineTemplates(1:size(templates, 1),:) = templates;
    coarseTemplates(1:size(decTemplates, 1),:) = decTemplates;
end
% imagesc(fineTemplates(1:length(kF),:))
% imagesc(coarseTemplates(1:length(kF_),:))
autogenLuts.DCOR.templates = [coarseTemplates(:);fineTemplates(:)];


%% PSNR
% this should be calculated offline (not firmware)
% psnrRegs = Pipe.DCOR.FRMW.genPSNRregs();
% autogenRegs = Firmware.mergeRegs(autogenRegs,psnrRegs);
%% ASIC
crse_len  = double(regs.GNRL.tmplLength)/double(autogenRegs.DCOR.decRatio);
autogenRegs.DCOR.loopCtrl=bitshift(uint32(uint8(ceil(crse_len / 66.0 ))),0)+bitshift(uint32(uint8(ceil(crse_len / 22.0 ))),8)+bitshift(uint32(uint8(ceil(regs.GNRL.tmplLength / 84.0 ))),16);

%%
tn=length(   autogenLuts.DCOR.templates);
assert(tn==64*(256+1024),'bad templates length!')
regs = Firmware.mergeRegs(regs,autogenRegs);


end

