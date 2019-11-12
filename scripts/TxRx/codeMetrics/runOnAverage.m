path='X:\Users\hila\TxRxinvest\CodeTestData\Test3\codeData\rawData';
disfolders=dir(path);
disfolders(strcmp({disfolders.name},'.'))=[]; disfolders(strcmp({disfolders.name},'..'))=[];
outputFolder='X:\Users\hila\TxRxinvest\CodeTestData\Test3\results\AverageAnalysis';
codesStruct='X:\Users\hila\TxRxinvest\CodesStruct.mat' ;
load('X:\Users\hila\TxRxinvest\CodeTestData\sysDelay.mat')
load(codesStruct);

%%
for i=1:length(disfolders)
    f=[path,'\',disfolders(i).name];
    CodeMat = dir([f,'\*.mat']);
    out=[outputFolder,'\',disfolders(i).name];
    mkdirSafe(out);
    for j=1:length(CodeMat)
        matName=CodeMat(j).name;
        codeName=strrep(matName,'.mat','');
        load([f,'\',matName]);
        transmitedCode=codes(strcmp({codes.name},codeName)).tCode; 
        [fast_mean,fast_std,code] = AnalyzeAverageCode(fast,transmitedCode,codeName,out);
        plotAndSave(code,fast_mean,codeName,out)
    end
end

function [] =plotAndSave(code,fast_mean,codeName,outPath)
h=figure();plot(code);
hold on
plot(fast_mean);
hold off
legend('code','mean');
grid minor;
title([strrep(codeName,'_','x'),': code mean vs origin']);

saveas(h,strcat(outPath,'\',codeName,'.fig'));
saveas(h,strcat(outPath,'\',codeName,'.png'));
end