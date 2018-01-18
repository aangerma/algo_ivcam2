function [regs, unitTestS] = psnrTableGen(Mcw,isDebug,isFast)
%% flags
if(nargin==0)
    Mcw = uint16(2^8);
    debug = 1;
    fastApprox = 1;
elseif(nargin==1)
    debug = 0;
    fastApprox = 0;
elseif(nargin==2)
    debug = isDebug;
    fastApprox = isDebug;
else
    debug = isDebug;
    fastApprox = isFast;
end

%% vars init

regType = {'ir', 'amb'};

%Ms,Mn: given later in the pipe so we need to simulate them
if(fastApprox)
    MnSim = linspace(0,2^12-1,2^10);
else
    MnSim = linspace(0,2^12-1,2^12);
end

%to get alpha (denoted here 'a') we need Ms and go back to alpha
if(fastApprox)
    alphaSim = linspace(0,2^12-1,2^10);
else
    alphaSim = linspace(0,2^12-1,2^12);
end

[MnSimT,aSimT] = meshgrid(MnSim,alphaSim);

%given during FW: Mcw
if(nargin==0)
    Mcw = 2^8;
else
    Mcw = double(Mcw);
end


%% calc
s = @(Mn) Mn*sqrt(pi/2);
gamma = @(Mn) (pi/2)^0.25*sqrt(max(Mcw-Mn,0));%Mcw > Mn always... it's an assumption

phi = @(x) cdf('Normal',x,0,1);

elem0 = @(Mn,a) gamma(Mn).*a./(2.*s(Mn));
elem1 = @(Mn,a) sqrt(s(Mn).^2+gamma(Mn).^2.*a);

elem2 = @(Mn,a) s(Mn).*exp(-0.5.*(elem0(Mn,a).^2));
elem3 = @(Mn,a) elem1(Mn,a).*exp(-gamma(Mn).*a.^2./(8.*elem1(Mn,a).^2));


Ms =@(Mn,a) 1./sqrt(2.*pi).*(elem2(Mn,a)+elem3(Mn,a))+gamma(Mn).*a./2.*(phi(gamma(Mn).*a./(2.*s(Mn)))-phi(-gamma(Mn).*a./(2.*elem1(Mn,a))));

%% find Ms
%  elem0(MnSim,aSim)
%  elem1(MnSim,aSim)
%  elem2(MnSim,aSim)
%  elem3(MnSim,aSim)

% %find Ms
MsSimT = Ms(MnSimT,aSimT);
MsSimT(isnan(MsSimT(:))) = 0; %x/0...
MsSimT(MsSimT>(2^12-1))=2^12-1; %overflow

if(fastApprox)
    MsSim = linspace(0,2^12-1,2^10);
else
    MsSim = linspace(0,2^12-1,2^12);
end

%% get alpha table
alphaT = nan(length(MsSim),length(MnSim));
for i=1:length(MnSim)
    for j = 1:length(MsSim)
        alpha = alphaSim(  minind(abs(MsSimT(:,i)-MsSim(j)))    );
        alphaT(j,i) = alpha;
    end
end

if(debug)
    
    f = figure;maximize(f);
    tabplot;
    subplot(121);imagesc([min(MnSim) max(MnSim)],[min(alphaSim) max(alphaSim)],MsSimT);xlabel('Mn == nest');ylabel('\alpha');title('Ms == ir');colorbar
    subplot(122); imagesc([min(MnSim) max(MnSim)],[min(MsSim) max(MsSim)],alphaT);title('\alpha');ylabel('Ms == ir');xlabel('Mn == nest');colorbar
end


%% get full PSNR table
sSim = s(MnSim);
psnrT = 10*log10(alphaT./repmat(sSim,size(alphaT,1),1));
psnrT(psnrT==inf)= nan;
psnrT(psnrT==-inf)= nan;

minPSNR = -40;
maxPSNR = 40;
assert(max(psnrT(:))<=maxPSNR && min(psnrT(:))>=minPSNR,'psnrT problem');

psnrT = (psnrT-minPSNR)/(maxPSNR-minPSNR)*(2^6-1);

%% crop unwanted edges
psnrTUnwantedMask = (isnan(psnrT));



for i=1:length(regType)
    if(strcmp(regType{i},'amb'))
        unwanted = (sum(~psnrTUnwantedMask,1)==0);
        simData = MnSim;
    else
        unwanted = (sum(~psnrTUnwantedMask,2)==0);
        simData = MsSim;
    end
    
    %let's find the start of the lut
    d=diff(unwanted);
    unwantedStart = floor(simData(find(d==-1,1)+1));
    if(~isempty(unwantedStart))
        regs.DCOR.([regType{i} 'StartLUT']) = uint16(unwantedStart);
    else
        regs.DCOR.([regType{i} 'StartLUT']) = uint16(0);
    end
    
    %we can squeeze the higher part of the 1D lut with the exp
    unwantedEndInd = round(simData(find(d==1,1,'last')))+1;
    if(~isempty(unwantedEndInd))
        expNeeded = ceil(log2(unwantedEndInd-double(regs.DCOR.([regType{i} 'StartLUT']))));
        regs.DCOR.([regType{i} 'LUTExp']) = uint8(6-(12-expNeeded));
    else
        regs.DCOR.([regType{i} 'LUTExp']) = uint8(6);
    end
    
end


lowIndIr = minind(abs(MsSim-double(regs.DCOR.irStartLUT)));
highIndIr = minind(abs(MsSim- (double(regs.DCOR.irStartLUT)+2^(6+double(regs.DCOR.irLUTExp)))  ));
lowIndAmb = minind(abs(MnSim-double(regs.DCOR.ambStartLUT)));
highIndAmb = minind(abs(MnSim-2^(6+double(regs.DCOR.ambLUTExp))));

psnrTReduced = psnrT(lowIndIr:highIndIr,lowIndAmb:highIndAmb);

if(debug)
    tabplot;
    
    subplot(131);imagesc([min(MnSim) max(MnSim)],[min(MsSim) max(MsSim)],psnrT);title('full PSNR table');ylabel('Ms == ir');xlabel('Mn == nest');colorbar
    
    subplot(132);imagesc([min(MnSim) max(MnSim)],[min(MsSim) max(MsSim)],psnrTUnwantedMask);title('psnr Table Unwanted Mask');ylabel('Ms == ir');xlabel('Mn == nest');
    
    subplot(133);imagesc([MnSim(lowIndAmb) MnSim(highIndAmb)],[MsSim(lowIndIr) MsSim(highIndIr)],psnrTReduced); title('psnr Table Reduced');ylabel('Ms == ir');xlabel('Mn == nest');
end

%% do non linear 2D quantization to get psnr LUT
psnrTgrad = imgradient(psnrTReduced);
psnrTgrad1D = cell(2,1);
for j=1:length(regType)
    psnrTgrad1D{j} = nansum(psnrTgrad,j);
    
    integral = sum(psnrTgrad1D{j});
    area = integral/16; %16X16 bins in 2D lut
    
    minStep = ceil(length(psnrTgrad1D{j})/64);%64 entries in 1D lut- so can't move 2 bins in less then minStep
    tmpSum = 0;
    
    qBinEdgesIndTmp = nan(17,1);
    qBinEdgesIndTmp(1) = 1;
    curInd = 1;
    
    for i=1:length(psnrTgrad1D{j})
        
        
        tmpSum = tmpSum+psnrTgrad1D{j}(i);
        if(i-qBinEdgesIndTmp(curInd)<minStep)
            continue;
        end
        
        if(tmpSum>=area)
            curInd = curInd+1;
            qBinEdgesIndTmp(curInd) = i;
            tmpSum = 0;
            
            if(curInd==16) %we can do finer quantization on the last one because of the padded zeros
                qBinEdgesIndTmp(end) = find(psnrTgrad1D{j}~=0,1,'last');
                break;
            end
            
            %integral over the remain func
            integral = sum(psnrTgrad1D{j}((i+1):end));
            area = integral/(16-curInd+1);
        end
        
    end
    
    assert(curInd==16,'was not able to devide to 16 bins')
    
    %get the map
    mappp = zeros(64,1);
    mappp(   ceil(   qBinEdgesIndTmp(2:end-1)/length(psnrTgrad1D{j})*64   )   ) = 1;
    qBinEdgesInd16Tmp = cumsum(mappp);
    
    assert(qBinEdgesInd16Tmp(1)==0 && qBinEdgesInd16Tmp(end)==15,'problem with 1D lut generation')
    
    qBinValInds.(regType{mod(j,2)+1}) = round(mean([qBinEdgesIndTmp(1:end-1) qBinEdgesIndTmp(2:end)],2));
    regs.DCOR.([regType{mod(j,2)+1} 'Map']) = uint8(qBinEdgesInd16Tmp);
    
end

%% Talm - Replaced 'for loop' with '2D interpolation' and scaled to the whole 0-63 range.
[irInd,ambInd] = ndgrid(qBinValInds.ir,qBinValInds.amb); 
psnrTfinal = interp2(psnrTReduced,ambInd,irInd);
minPsnr = min(psnrTfinal(psnrTfinal>0));
maxPsnr = max(psnrTfinal(psnrTfinal>0));
psnrTfinal(isnan(psnrTfinal)) = 0;
psnrTfinal(psnrTfinal==0) = minPsnr;
psnrTfinal = round((psnrTfinal-minPsnr)/(maxPsnr-minPsnr)*(2^6-1));

qBinValInds.ir = round(qBinValInds.ir);
qBinValInds.amb = round(qBinValInds.amb);


regs.DCOR.psnr = uint8(psnrTfinal(:));
if(debug)
    %%
    tabplot;
    for j=1:length(regType)
        subplot(1,2,j);
        data = psnrTgrad1D{mod(j,2)+1};
        plot(data,'lineWidth',3);hold on;
        maxVal = max(data);
        minVal = min(data);
        x = qBinValInds.(regType{j});
        y = minVal:maxVal;
        for i=1:16
            plot(x(i)*ones(size(y)),y,'k');
        end
        axis tight
        title([regType{j} ' 1D LUT quantization'])
    end
    
    tabplot;
    subplot(221);imagesc([MnSim(lowIndAmb) MnSim(highIndAmb)],[MsSim(lowIndIr) MsSim(highIndIr)],psnrTgrad);
    title('psnr grad map');ylabel('Ms == ir');xlabel('Mn == nest');
    
    subplot(222);cla;imagesc([MnSim(lowIndAmb) MnSim(highIndAmb)],[MsSim(lowIndIr) MsSim(highIndIr)],psnrTReduced);hold on;
    
    y = linspace(MsSim(lowIndIr), MsSim(highIndIr),size(psnrTReduced,1));
    for i=1:16
        plot((MnSim(qBinValInds.amb(i)+lowIndAmb-1))*ones(size(y)),y);
    end
    
    x = linspace(MnSim(lowIndAmb), MnSim(highIndAmb),size(psnrTReduced,2));
    for i=1:16
        plot(x,MsSim(qBinValInds.ir(i)+lowIndIr-1)*ones(size(x)));
    end
    title('non linear quantization')
    ylabel('Ms == ir');xlabel('Mn == nest');
    
    subplot(223);imagesc(psnrTfinal); title('final psnr LUT')
    subplot(224);imagesc(reshape(regs.DCOR.psnr,16,16)); title('final psnr LUT uint16')
end

%% for unit test
unitTestS.Ms = MsSim;
unitTestS.Mn = MnSim;
unitTestS.psnrT = psnrT;
end


