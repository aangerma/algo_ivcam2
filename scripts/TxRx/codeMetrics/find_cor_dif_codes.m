%%
clear all;
close all;

%% input
codesStruct='X:\Users\tomer\FG\codes.mat' ;
load(codesStruct);

dataPath='X:\Users\tomer\data32\raw\filtered';
distance=450 ;%600:50:3950;
%% run on code
codeFolder='X:\Users\tomer\codes_data\450';
Codefiles=dir(strcat(codeFolder,'\*.mat'));
filesName={Codefiles.name};
codesNames=cellfun(@getStrName,filesName,'UniformOutput', false);
%% output
outPath='X:\Users\hila\L520\TxRx\AnalyzeCodes\diffCodes\1';
mkdir(outPath);
%% params
sample_dist=18.7314;
system_delay= 7394;
decRatio=2;
downSamplingR=2^decRatio;
fineCorrRange=16;
validTh=30; % [mm]
%%
FullRes=cell(length(distance),1);
for j=1:length(distance)
    results(length(Codefiles))=struct;
    for i=1:length(Codefiles)
        codeName=codesNames{i};
        results(i).codeName=codeName;
        code_i=find(strcmp({codes.name},codeName));
        TxFullcode=codes(code_i).tCode;
        %         temp=load(strcat(dataPath,'\1\',num2str(distance(i)),'.mat'));
        temp=load(strcat(codeFolder,'\',codeName,'.mat'));
        cma_=temp.fast;
        [z] = calculateZ(downSamplingR,fineCorrRange,sample_dist,system_delay,TxFullcode,cma_);
        results(i).medianz=median(z);
        diffVec=z-results(i).medianz;
        validBool=abs(diffVec)<validTh;
        results(i).validPrc=sum(validBool)/length(diffVec);
        results(i).validL1=norm(z(validBool)-results(i).medianz,1);
        results(i).validL2=norm(z(validBool)-results(i).medianz,2);
        %     zData{i}=z;
        
        results(i).err95=prctile(abs(diffVec),95);
        results(i).err5=prctile(abs(diffVec),5);
        results(i).err50=prctile(abs(diffVec),50);
        results(i).meanError=mean(diffVec);
        
        results(i).mean=mean(z);
        h=figure(); imagesc(cma_); title(strcat('cma_',codeName), 'Interpreter', 'none');
        saveas(h,strcat(outPath,'\',num2str(distance(j)),'_',codeName,'.png'));
    end
    FullRes{j}=results;
end

%%
% x=[results.medianz];
% xname='median z'; xtick=[];

xtick={results.codeName};
x=1:length(xtick);
xname='codeName';

%%
plotAndSave(x,[results.validPrc],strcat('Valid prc vs',xname),'ValidPrc',outPath,xtick);
plotAndSave(x,[results.validL1],strcat('L1 of Valid transmissions from median z vs',xname),'L1',outPath,xtick);
plotAndSave(x,[results.validL2],strcat('L2 of Valid transmissions from median z vs',xname),'L2',outPath,xtick);
plotAndSave(x,[results.err5],strcat('Prctile 5 of abs(error) vs',xname),'errorPrc5',outPath,xtick);
plotAndSave(x,[results.err95],strcat('Prctile 95 of abs(error) vs',xname),'errorPrc95',outPath,xtick);
plotAndSave(x,[results.err50],strcat('Prctile 50 of abs(error) vs',xname),'errorPrc50',outPath,xtick);
plotAndSave(x,[results.meanError],strcat('mean error vs',xname),'meanError',outPath,xtick);


function plotAndSave(x,y,titleS,fileName,outPath,xtick)
h=figure(); plot(x,y);title(titleS); grid minor;
if(~isempty(xtick))
    xticklabels(xtick)
    set(gca,'TickLabelInterpreter','none')
end
saveas(h,strcat(outPath,'\',fileName,'.png'));

end

function [codeName]=getStrName(s)
tmp=strsplit(s,'.');
codeName=tmp{1};
end