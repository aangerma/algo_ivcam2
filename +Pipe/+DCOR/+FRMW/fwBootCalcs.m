function [regs,autogenRegs,autogenLuts] = fwBootCalcs(regs,luts,autogenRegs,autogenLuts)
%% =======================================DCOR - Input registers ==============================================
% register input            %   source conf/cal/Autogen
%==============================================================================================================
% GNRL.sampleRate           %   conf
% FRMW.coarseSampleRate     %   conf
% regs.FRMW.outIRcmaBin     %   conf
% GNRL.imgVsize             %   conf
% GNRL.codeLength           %   conf
% DEST.txFRQpd              %   conf
% FRMW.sampleDist           %   Auto gen
% GNRL.tmplLength           %   Auto gen
% FRMW.txCode               %   conf
% DCOR.decRatio             %   Auto gen
%% =======================================DCOR - output Auto gen registers ====================================
% register output            %   description
%%==============================================================================================================
% DCOR.yScaler              %   confconfigure the select template selected table in RXTX mode.
% DCOR.decRatio             %   ratio between coarse and fine in DCOR block
% DCOR.outIRcmaIndex        %   debug mode to output CMA bin out
% DCOR.coarseTmplLength     %   coarse template Length
% DCOR.coarseMasking        %   form multi focal mode currntly "bypass" values
% DCOR.loopCtrl             %   asic use 
% DCORtmpltFine             %   memory in asic storing the fine template 8192*4
% DCORtmpltCrse             %   memory in asic storing the coarse template 2048*4

autogenRegs.DCOR.yScaler = uint8(zeros(128,1)); %it's uint4
autogenRegs.DCOR.decRatio = uint8(log2(double(regs.GNRL.sampleRate)/double(regs.FRMW.coarseSampleRate)));

autogenRegs.DCOR.outIRcmaIndex = uint8([floor(double(regs.FRMW.outIRcmaBin)/84) mod(regs.FRMW.outIRcmaBin,84)]);

autogenRegs.DCOR.yScalerDivExp = uint8(ceil(log2(double(regs.GNRL.imgVsize)))-7);
downSamplingR = 2 ^ double(autogenRegs.DCOR.decRatio);
autogenRegs.DCOR.coarseTmplLength = uint16(double(regs.GNRL.codeLength)*double(regs.GNRL.sampleRate)/downSamplingR);


%% coarse masking
pdSampleOffsetFine = (regs.DEST.txFRQpd./regs.FRMW.sampleDist); %ofsset caused by pd [mm]/ offset caused by pd [mm/sample] -> [sample]
pdSampleOffsetCoarse = uint8(floor(pdSampleOffsetFine/(downSamplingR)+0.5));

maskLength = double(regs.GNRL.tmplLength)/downSamplingR;

coarseMasking = repmat(regs.FRMW.coarseMasking,3,1).';
for i=1:3
    coarseMasking(1:maskLength,i) = circshift(coarseMasking(1:maskLength,i),pdSampleOffsetCoarse(i));
    coarseMasking(1:maskLength,i) = circshift(coarseMasking(1:maskLength,i),-1);%due to HW implementation
end
autogenRegs.DCOR.coarseMasking = coarseMasking(:).';

%% prepare templates
codevec = vec(fliplr(dec2bin(regs.FRMW.txCode(:),32))')=='1';
codevec = codevec(1:regs.GNRL.codeLength);
codevec = flipud(codevec);%ASIC ALIGNMENT

SymbolCode_3bit = circshift(codevec,-1)+2*codevec+4*circshift(codevec,1);
nF = double(regs.GNRL.codeLength)*double(regs.GNRL.sampleRate);
nC =  bitshift(nF,-double(autogenRegs.DCOR.decRatio));
nTemplates = iff(nF==2048,32,64);
[tamplate_entery_LUT, result] = getTamplateSymbolTransLUT(luts , regs.GNRL.sampleRate); %
if( result == true) 
    templates = (zeros(nF,64));
    for i=1:nTemplates
        kF = reshape(tamplate_entery_LUT(:,SymbolCode_3bit(1)+1,i),[1,regs.GNRL.sampleRate]);
        for j=2:regs.GNRL.codeLength
            kF = [kF reshape(tamplate_entery_LUT(:,SymbolCode_3bit(j)+1,i),[1,regs.GNRL.sampleRate])];
        end
        templates(:,i)=kF;
    end
else   %default case 
    kF = double(vec(repmat(codevec,1,regs.GNRL.sampleRate)'));
    nF =  length(kF)  ; 
    nC =  bitshift(nF,-double(autogenRegs.DCOR.decRatio));
    nTemplates = iff(nF==2048,32,64);
    
    templates = (zeros(nF,64));
    for i=1:nTemplates 
        templates(:,i)=kF;
    end
    templates = uint8(round(min(1,max(0,templates))*7));
end
tbl2uint32 = @(t) typecast(vec(flipud(reshape(uint8(sum(bsxfun(@bitshift,reshape(t(:),2,[]),[4;0]))),4,[]))),'uint32');

%% gen fine from template
tmplF = templates;
% replicate to 1024
tmplF = tmplF(mod(0:1023,nF)+1,:);
tmplF = circshift(tmplF,[mod(1024,nF),0]);
tmplF(1:mod(1024,nF),:) = tmplF(end-mod(1024,nF)+1:end,:);

tmplF  = circshift(tmplF ,[(nF-16),0]);
if(~regs.FRMW.dcorTemplatesFromFile || all(luts.DCOR.tmpltFine==0))%already set using aux file, do not set!
    autogenLuts.DCOR.tmpltFine = tbl2uint32(tmplF);
end
%% gen coarse from template
tmplC=bitshift(uint8(permute(sum(reshape(templates,downSamplingR,[],size(templates,2))),[2 3 1])),-double(autogenRegs.DCOR.decRatio));
% replicate to 256
tmplC = tmplC(mod(0:255,nC)+1,:);
tmplC = circshift(tmplC,[mod(256,nC),0]);
tmplC(1:mod(256,nC),:) = tmplC(end-mod(256,nC)+1:end,:);
if(~regs.FRMW.dcorTemplatesFromFile || all(luts.DCOR.tmpltCrse==0))%already set using aux file, do not set!
    autogenLuts.DCOR.tmpltCrse = tbl2uint32(tmplC);
end
%% PSNR
% this should be calculated offline (not firmware)
% psnrRegs = Pipe.DCOR.FRMW.genPSNRregs();
% autogenRegs = Firmware.mergeRegs(autogenRegs,psnrRegs);
%% ASIC memory compatable 
crse_len  = double(regs.GNRL.tmplLength)/downSamplingR;
autogenRegs.DCOR.loopCtrl=...
    bitshift(uint32(uint8(ceil(crse_len / 66.0 ))),0)+...
    bitshift(uint32(uint8(ceil(crse_len / 22.0 ))),8)+...
    bitshift(uint32(uint8(ceil(double(regs.GNRL.tmplLength) / 84.0 ))),16);

%%
regs = Firmware.mergeRegs(regs,autogenRegs);


end
function [tamplate_symbol_trans_LUT , result] = getTamplateSymbolTransLUT(luts,rx2tx)
%% the function uncompress the lut and return the transitation table for the requested rx2tx
%{
    the order in luts file
    rx2tx 16
        template 1
            trans 000
                 1 .... rx2tx symbol bit sample
             .
             .
            trans 111
        template 2
            .
            .
        template 64
    rx2tx 8
        .
        .
    rx2tx 4
        .
        .
%}    
    result              = true;
    nTemplate           = 64;
    nSymbolTranState    = 8; % 000 ,001 ... ,111
    %tamplate_symbol_trans_LUT = zeros(64,8,rx2tx);
    if(all(luts.FRMW.tmpTrans==0))
       result = false;
       tamplate_symbol_trans_LUT = zeros(64,8,rx2tx);
       return
    end
    b = luts.FRMW.tmpTrans;
    b = [bitand(b(1,:),7) ; bitand(bitshift(b(1,:),-4),7) ; bitand(bitshift(b(1,:),-8),7) ; bitand(bitshift(b(1,:),-12),7) ; ...
        bitand(bitshift(b(1,:),-16),7) ; bitand(bitshift(b(1,:),-20),7) ; bitand(bitshift(b(1,:),-24),7) ; bitand(bitshift(b(1,:),-28),7)];
    b = b(:);
    % luts.FRMW.tmpTrans - is compressed for 8 value in 32bit. 
    % b - uncompressed values 
    
    switch rx2tx   
        case 16
            start_off = 1;
        case 8
            start_off = 1 + nTemplate*nSymbolTranState*16; 
        case 4            
            start_off = 1 + nTemplate*nSymbolTranState*(16+8);
        otherwise
           result = false;
           return
    end
    end_off = double(start_off) + double(64)*double(8*rx2tx) - 1;

    tamplate_symbol_trans_LUT = reshape(b(start_off:end_off),[rx2tx,8,64]);
end 


