%%
clear all;
close all;

%% input
normlizeTo127=0;
if normlizeTo127
    codesStruct='X:\Users\hila\TxRxinvest\NormCodeStruct.mat';
    load('X:\Users\hila\TxRxinvest\CodeTestData\sysDelayNorm.mat')
else
    codesStruct='X:\Users\hila\TxRxinvest\CodesStruct.mat' ;
    load('X:\Users\hila\TxRxinvest\CodeTestData\sysDelay.mat')
end
load(codesStruct);

dataPath='X:\Users\hila\TxRxinvest\CodeTestData\Test3\codeData\rawData';
disfolders=dir(dataPath);
disfolders(strcmp({disfolders.name},'.'))=[]; disfolders(strcmp({disfolders.name},'..'))=[];

distance=sort(str2num(str2mat({disfolders.name}))); 
%% run on code
codeNames={codes.name};
%% output
outPath='X:\Users\hila\TxRxinvest\CodeTestData\Test3\results\validTh_300_16sampleDist';
mkdirSafe(outPath);
saveAbsDiffErr=false; 
%% params
sample_dist=18.7314;
decRatio=2;
downSamplingR=2^decRatio;
fineCorrRange=16;
validTh=fineCorrRange*sample_dist; % [mm]
%%
DisRes=cell(length(distance),1);
for j=1:length(distance)
    dataFolder=strcat(dataPath,'\',num2str(distance(j)));
    CodeMat = dir([dataFolder,'\*.mat']);
    clear results ;
    results(length(CodeMat))=struct;
    for i=1:length(CodeMat)
        matName=CodeMat(i).name;
        codeName=strrep(matName,'.mat','');
        codePath=strcat(dataFolder,'\',matName);
        results(i).codeName=codeName;
        code_i=find(strcmp({codes.name},codeName));
        TxFullcode=codes(code_i).tCode;
        system_delay= sysDel.SystemDelay(strcmp(sysDel.codeNames,codeName));
        %         temp=load(strcat(dataPath,'\1\',num2str(distance(i)),'.mat'));
        temp=load(codePath);
        cma_=temp.fast;
        
        if normlizeTo127
            [cma_]= normelizeCma(cma_, codes(code_i).codeLength);
        end
        DC=sum(cma_,1)/length(TxFullcode);
        results(i).medianDC=nanmedian(DC);
        results(i).stdDC=std(DC);
        saveStruct=struct(); 
        if saveAbsDiffErr
        saveStruct.path=strcat(outPath,'\AbsDiffErr\','d',num2str(distance(j))); 
        mkdir(saveStruct.path) ; 
        saveStruct.distance=distance(j); 
        saveStruct.codeName=codeName; 
        end 
        [zValueFullCor,zValueFromCoarseOnly,zValueFromFineOnly,results(i).validCoarse] = calculateZ(downSamplingR,fineCorrRange,sample_dist,system_delay,TxFullcode,cma_,saveAbsDiffErr,saveStruct);
        zValueFullCor(isnan(zValueFullCor))=[];
        results(i).medianz=nanmedian(zValueFullCor);
        results(i).zStd=nanstd(zValueFullCor);
        diffVec=zValueFullCor-results(i).medianz;
        BoundedDiffVec=abs(diffVec); BoundedDiffVec(BoundedDiffVec>validTh)=validTh; 
        validBool=abs(diffVec)<validTh;
        results(i).validPrc=sum(validBool)/length(diffVec);
        results(i).validL1=norm(zValueFullCor(validBool)-results(i).medianz,1)/sum(validBool);
        results(i).validL2=norm(zValueFullCor(validBool)-results(i).medianz,2)/sum(validBool);
        results(i).validZstd=nanstd(zValueFullCor(validBool));

        results(i).BoundedL1=norm(BoundedDiffVec,1)/length(BoundedDiffVec);
        results(i).med_zValueFullCor=nanmedian(zValueFullCor); 
        results(i).med_zValueFromCoarseOnly=nanmedian(zValueFromCoarseOnly); 
        results(i).med_zValueFromFineOnly=nanmedian(zValueFromFineOnly); 

        %     zData{i}=z;
        
        results(i).err95=prctile(abs(diffVec),95);
        results(i).err5=prctile(abs(diffVec),5);
        results(i).err50=prctile(abs(diffVec),50);
        results(i).meanError=mean(diffVec);
        
        results(i).mean=mean(zValueFullCor);
%         h=figure(); imagesc(cma_); title(strcat('cma_',codeName), 'Interpreter', 'none');
%         saveas(h,strcat(outPath,'\',num2str(distance(j)),'_',codeName,'.png'));
    end
    DisRes{j}=results;
end

%%

codesNames={results.codeName};
codesNum=length(codesNames);


%% vs code type
xtick={results.codeName};
x=1:length(xtick);
xname=' codeName';
p1=strcat(outPath,'/vsCode'); mkdir(p1) ;
runPlots(x,xname,xtick, DisRes ,cellstr(num2str(distance, 'd=%-d')) ,p1,validTh);
%% vs distance
xtick=cellstr(num2str(distance));
x=distance;
xname='distance';
codeRes=cell(codesNum,1);
for k=1:codesNum
    for k2=1:length(distance)
        distanceRes=DisRes{k2};
        disCodeRes=distanceRes(k);
        disCodeRes.distance=distance(k2);
        codeRes{k,k2}=disCodeRes;
    end
end
p2=strcat(outPath,'/vsDistance'); mkdir(p2) ;
runPlots(x,xname,xtick, codeRes ,codesNames ,p2,validTh);

%%
function runPlots(x,xAxisName,xtick, Yresults ,yVecData,outPath, validTh )
cmap=[rand(length(Yresults),1),rand(length(Yresults),1),rand(length(Yresults),1)];
plotAndSave(cmap,x,xAxisName,'validPrc',Yresults,yVecData,strcat('Valid prc vs',xAxisName, ' valid Th ' ,num2str(validTh)),'ValidPrc',outPath,xtick);
plotAndSave(cmap,x,xAxisName,'medianz',Yresults,yVecData,strcat('medianz vs ',xAxisName),'medianz',outPath,xtick);
plotAndSave(cmap,x,xAxisName,'zStd',Yresults,yVecData,strcat('zStd vs ',xAxisName),'zStd',outPath,xtick);
plotAndSave(cmap,x,xAxisName,'validL1',Yresults,yVecData,strcat('L1 of Valid transmissions from median z vs ',xAxisName, ' valid Th ' ,num2str(validTh)),'L1',outPath,xtick);
plotAndSave(cmap,x,xAxisName,'validL2',Yresults,yVecData,strcat('L2 of Valid transmissions from median z vs ',xAxisName, ' valid Th ' ,num2str(validTh)),'L2',outPath,xtick);
plotAndSave(cmap,x,xAxisName,'BoundedL1',Yresults,yVecData,strcat('L1 of Truncated error by threshold from median z vs ',xAxisName, ' valid Th ' ,num2str(validTh)),'BoundedL1',outPath,xtick);
plotAndSave(cmap,x,xAxisName,'validZstd',Yresults,yVecData,strcat('zStd of valid vs ',xAxisName, ' valid Th ' ,num2str(validTh)),'zStdOfValid',outPath,xtick);

plotAndSave(cmap,x,xAxisName,'err5',Yresults,yVecData,strcat('Prctile 5 of abs(error) vs ',xAxisName),'errorPrc5',outPath,xtick);
plotAndSave(cmap,x,xAxisName,'err95',Yresults,yVecData,strcat('Prctile 95 of abs(error) vs ',xAxisName),'errorPrc95',outPath,xtick);
plotAndSave(cmap,x,xAxisName,'err50',Yresults,yVecData,strcat('Prctile 50 of abs(error) vs ',xAxisName),'errorPrc50',outPath,xtick);
plotAndSave(cmap,x,xAxisName,'meanError',Yresults,yVecData,strcat('mean error vs ',xAxisName),'meanError',outPath,xtick);
plotAndSave(cmap,x,xAxisName,'medianDC',Yresults,yVecData,strcat('median dc vs ',xAxisName),'medianDC',outPath,xtick);
plotAndSave(cmap,x,xAxisName,'stdDC',Yresults,yVecData,strcat('std DC vs ',xAxisName),'stdDC',outPath,xtick);

plotAndSave(cmap,x,xAxisName,'med_zValueFullCor',Yresults,yVecData,strcat('medzValueFullCor vs ',xAxisName),'med_zValueFullCor',outPath,xtick);
plotAndSave(cmap,x,xAxisName,'med_zValueFromCoarseOnly',Yresults,yVecData,strcat('medzValueFromCoarseOnly vs ',xAxisName),'med_zValueFromCoarseOnly',outPath,xtick);
plotAndSave(cmap,x,xAxisName,'med_zValueFromFineOnly',Yresults,yVecData,strcat('medzValueFromFineOnly vs ',xAxisName),'med_zValueFromFineOnly',outPath,xtick);
plotAndSave(cmap,x,xAxisName,'validCoarse',Yresults,yVecData,strcat('validCoarse vs ',xAxisName),'validCoarse',outPath,xtick);

end

function plotAndSave(cmap,x,xAxisName,metricName,YRes, ynames,titleS,fileName,outPath,xtick)
h=figure('units','normalized','outerposition',[0 0 1 1]); hold all;
ynames=strrep(ynames,'_',' ');
for i=1:length(ynames)
    s=[YRes{i,:}]';
    if (strcmp(xAxisName,'distance'))
        plot(x,[s.(metricName)],'Color',cmap(i,:));
    else
        scatter(x,[s.(metricName)],'filled');
    end
end
title(titleS); grid minor;
legend(ynames);
if(~isempty(xtick))
    xticks(x);
    xticklabels(xtick);
    set(gca,'TickLabelInterpreter','none')
end
saveas(h,strcat(outPath,'\',fileName,'.fig'));
saveas(h,strcat(outPath,'\',fileName,'.png'));

end

function [NormedCma]= normelizeCma(origCma, codeLength)
if codeLength==127
    NormedCma=origCma;
else
    if codeLength>50
        a=origCma(:,1:2:end);
        b=origCma(:,2:2:end);
        l=min(size(a,2),size(b,2));
        NormedCma=[a(:,1:l) ; b(:,1:l)] ;
    else %32
        a=origCma(:,1:4:end); b=origCma(:,2:4:end);
        c=origCma(:,3:4:end); d=origCma(:,3:4:end);
        
        l=min([size(a,2),size(b,2),size(c,2),size(d,2)]);
        NormedCma=[a(:,1:l) ; b(:,1:l);c(:,1:l);d(:,1:l)] ;
    end
end

end
