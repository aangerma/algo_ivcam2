%%
clear all;
close all;

%% input
normlizeTo127=0;
if normlizeTo127
    codesStruct='X:\Users\hila\L520\TxRx\NormCodeStruct.mat';
    load('X:\Users\hila\L520\TxRx\CodeTestData\sysDelayNorm.mat')
else
    codesStruct='X:\Users\hila\L520\TxRx\CodesStruct.mat' ;
    load('X:\Users\hila\L520\TxRx\CodeTestData\sysDelay.mat')
end
load(codesStruct);

dataPath='X:\Users\hila\L520\TxRx\CodeTestData\Test1\codesData';
distance=[375,430,500,571,682,774,883,1001,1105,1200,1500];
%% run on code
codeNames={'16_4'};%{codes.name};
%% output
outPath='X:\Users\hila\L520\TxRx\CodeTestData\Test1\resultsAnalyzeFineCor';
mkdirSafe(outPath);
%% params
sample_dist=18.7314;
decRatio=2;
downSamplingR=2^decRatio;
fineCorrRange=16;
validTh=50; % [mm]
%%
DisRes=cell(length(distance),1);
for j=1:length(distance)
    dataFolder=strcat(dataPath,'\',num2str(distance(j)));
    clear results ;
    results(length(codeNames))=struct;
    for i=1:length(codeNames)
        codePath=strcat(dataFolder,'\',codeNames{i},'.mat');
        codeName=codeNames{i};
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
        [z] = calculateZ(downSamplingR,fineCorrRange,sample_dist,system_delay,TxFullcode,cma_);
        z(isnan(z))=[];
        results(i).medianz=nanmedian(z);
        results(i).zStd=nanstd(z);
        diffVec=z-results(i).medianz;
        BoundedDiffVec=abs(diffVec); BoundedDiffVec(BoundedDiffVec>validTh)=validTh; 
        validBool=abs(diffVec)<validTh;
        results(i).validPrc=sum(validBool)/length(diffVec);
        results(i).validL1=norm(z(validBool)-results(i).medianz,1)/sum(validBool);
        results(i).validL2=norm(z(validBool)-results(i).medianz,2)/sum(validBool);
        results(i).BoundedL1=norm(BoundedDiffVec,1)/length(BoundedDiffVec);

        %     zData{i}=z;
        
        results(i).err95=prctile(abs(diffVec),95);
        results(i).err5=prctile(abs(diffVec),5);
        results(i).err50=prctile(abs(diffVec),50);
        results(i).meanError=mean(diffVec);
        
        results(i).mean=mean(z);
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
runPlots(x,xname,xtick, DisRes ,cellstr(num2str(distance', 'd=%-d')) ,p1);
%% vs distance
xtick=cellstr(num2str(distance', 'd=%-d'));
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
runPlots(x,xname,xtick, codeRes ,codesNames ,p2);


%%
function runPlots(x,xAxisName,xtick, Yresults ,yVecData,outPath )
cmap=[rand(length(Yresults),1),rand(length(Yresults),1),rand(length(Yresults),1)];
plotAndSave(cmap,x,xAxisName,'validPrc',Yresults,yVecData,strcat('Valid prc vs',xAxisName),'ValidPrc',outPath,xtick);
plotAndSave(cmap,x,xAxisName,'medianz',Yresults,yVecData,strcat('medianz vs',xAxisName),'medianz',outPath,xtick);
plotAndSave(cmap,x,xAxisName,'zStd',Yresults,yVecData,strcat('zStd vs',xAxisName),'zStd',outPath,xtick);
plotAndSave(cmap,x,xAxisName,'validL1',Yresults,yVecData,strcat('L1 of Valid transmissions from median z vs ',xAxisName),'L1',outPath,xtick);
plotAndSave(cmap,x,xAxisName,'validL2',Yresults,yVecData,strcat('L2 of Valid transmissions from median z vs ',xAxisName),'L2',outPath,xtick);
plotAndSave(cmap,x,xAxisName,'BoundedL1',Yresults,yVecData,strcat('L1 of Truncated error by threshold from median z vs ',xAxisName),'BoundedL1',outPath,xtick);

plotAndSave(cmap,x,xAxisName,'err5',Yresults,yVecData,strcat('Prctile 5 of abs(error) vs ',xAxisName),'errorPrc5',outPath,xtick);
plotAndSave(cmap,x,xAxisName,'err95',Yresults,yVecData,strcat('Prctile 95 of abs(error) vs ',xAxisName),'errorPrc95',outPath,xtick);
plotAndSave(cmap,x,xAxisName,'err50',Yresults,yVecData,strcat('Prctile 50 of abs(error) vs ',xAxisName),'errorPrc50',outPath,xtick);
plotAndSave(cmap,x,xAxisName,'meanError',Yresults,yVecData,strcat('mean error vs ',xAxisName),'meanError',outPath,xtick);
plotAndSave(cmap,x,xAxisName,'medianDC',Yresults,yVecData,strcat('median dc vs ',xAxisName),'medianDC',outPath,xtick);
plotAndSave(cmap,x,xAxisName,'stdDC',Yresults,yVecData,strcat('std DC vs ',xAxisName),'stdDC',outPath,xtick);
end

function plotAndSave(cmap,x,xAxisName,metricName,YRes, ynames,titleS,fileName,outPath,xtick)
h=figure('units','normalized','outerposition',[0 0 1 1]); hold all;

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
