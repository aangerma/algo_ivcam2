function [zValueFullCor,zValueFromCoarseOnly,zValueFromFineOnly,validCoarse] = calculateZ(coarseDownSamplingR,fineCorrRange,sample_dist,system_delay,TxFullcode,cma,saveAbsDiffErr,saveStruct)
max_dist=sample_dist*length(TxFullcode);

%% coarse correlation
[corrOffset,zValueFromCoarseOnly] = coarseCor(TxFullcode,coarseDownSamplingR,cma,sample_dist,max_dist,system_delay);

%% fine correlation
[peak_index_FullCor,~] = fineCor(fineCorrRange,coarseDownSamplingR,TxFullcode,corrOffset,cma);

% fine only
cor_dec = Utils.correlator(uint16(cma), uint8(TxFullcode));
[~, maxIndDec] = max(cor_dec);
peak_index_fineOnly = maxIndDec-1;
peak_index_fineOnly = permute(peak_index_fineOnly,[2 1]);

RTDonlyfine = peak_index_fineOnly .* sample_dist;
zValueFromFineOnly = mod(RTDonlyfine-system_delay,max_dist)';

%%

roundTripDistanceFullCor = peak_index_FullCor .* sample_dist;
zValueFullCor = mod(roundTripDistanceFullCor-system_delay,max_dist)';

%% save
AbsdiffError_coarseOnly=abs(zValueFromCoarseOnly-median(zValueFromCoarseOnly));
AbsdiffError_fineOnly=abs(zValueFromFineOnly-median(zValueFromFineOnly));
AbsdiffError_fullCor=abs(zValueFullCor-median(zValueFullCor));
if(saveAbsDiffErr)
    th=sample_dist*fineCorrRange; 
    plotErros(AbsdiffError_coarseOnly,AbsdiffError_fineOnly,AbsdiffError_fullCor,saveStruct,th,sample_dist);
end

validCoarse=sum((AbsdiffError_coarseOnly<(fineCorrRange/coarseDownSamplingR*sample_dist)))/length(AbsdiffError_coarseOnly); 
end

function []=plotErros(AbsdiffError_coarseOnly,AbsdiffError_fineOnly,AbsdiffError_fullCor,saveStruct,th,sampleDist)



h=figure('units','normalized','outerposition',[0 0 1 1]); hold all;
subplot(1,3,1); plot(AbsdiffError_coarseOnly,'*','color','r'); grid minor;  title(strcat('d=',num2str(saveStruct.distance),' code ',strrep(saveStruct.codeName,'_','x'),': abs diff error- coarseOnly') );
subplot(1,3,2); plot(AbsdiffError_fineOnly,'*','color','g'); grid minor;  title(strcat('d=',num2str(saveStruct.distance),' code ',strrep(saveStruct.codeName,'_','x'),': abs diff error- fineOnly') );
subplot(1,3,3); plot(AbsdiffError_fullCor,'*','color','b'); grid minor;  title(strcat('d=',num2str(saveStruct.distance),' code ',strrep(saveStruct.codeName,'_','x'),': abs diff error- full corraltion') );
saveas(h,strcat(saveStruct.path,'\',saveStruct.codeName,'.fig'));
saveas(h,strcat(saveStruct.path,'\',saveStruct.codeName,'.png'));
h=figure('units','normalized','outerposition',[0 0 1 1]); hold all;
subplot(2,3,1); histogram(AbsdiffError_coarseOnly,[sampleDist/2:sampleDist:th]); grid minor;  title(strcat('d=',num2str(saveStruct.distance),' code ',strrep(saveStruct.codeName,'_','x'),': valid abs diff error- coarseOnly') );
subplot(2,3,2); histogram(AbsdiffError_fineOnly,[sampleDist/2:sampleDist:th]); grid minor;  title(strcat('d=',num2str(saveStruct.distance),' code ',strrep(saveStruct.codeName,'_','x'),': valid abs diff error- fineOnly') );
subplot(2,3,3); histogram(AbsdiffError_fullCor,[sampleDist/2:sampleDist:th]); grid minor;  title(strcat('d=',num2str(saveStruct.distance),' code ',strrep(saveStruct.codeName,'_','x'),': valid abs diff error- full corraltion') );
subplot(2,3,4); histogram(AbsdiffError_coarseOnly,[(th+0.5*sampleDist):sampleDist:max(max(2*th,AbsdiffError_fullCor))]); grid minor;  title(strcat('d=',num2str(saveStruct.distance),' code ',strrep(saveStruct.codeName,'_','x'),':  abs diff error- coarseOnly') );
subplot(2,3,5); histogram(AbsdiffError_fineOnly,[(th+0.5*sampleDist):sampleDist:max(max(2*th,AbsdiffError_fullCor))]); grid minor;  title(strcat('d=',num2str(saveStruct.distance),' code ',strrep(saveStruct.codeName,'_','x'),':  abs diff error- fineOnly') );
subplot(2,3,6); histogram(AbsdiffError_fullCor,[(th+0.5*sampleDist):sampleDist:max(max(2*th,AbsdiffError_fullCor))]); grid minor;  title(strcat('d=',num2str(saveStruct.distance),' code ',strrep(saveStruct.codeName,'_','x'),':  abs diff error- full corraltion') );


saveas(h,strcat(saveStruct.path,'\hist',saveStruct.codeName,'.fig'));
saveas(h,strcat(saveStruct.path,'\hist',saveStruct.codeName,'.png'));
end