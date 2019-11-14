basePath = 'X:\Users\mkiperwa\algo2ValWrgb\fromTesters\';%'X:\Users\mkiperwa\algo2ValWrgb';
unitNumber = {'F9340026\Algo2 3.08.0 25C Thermo';'F9340026\Algo2 3.08.0 10C Self Heating';'F9340026\Algo2 3.08.0 10C Thermo';...
    'F9340026\Algo2 3.08.0 Self Heating'};%{'F9340021';'F9340203'; 'F9340255'};

for ixUnit = 1:numel(unitNumber)
    folderData = dir([basePath '\' unitNumber{ixUnit}]);
    %     for ixFldr = 1:numel(folderData)
    %         if ~contains(folderData(ixFldr).name,'TC')
    %             continue;
    %         end
    %         calibDataFullPath = [basePath '\' unitNumber{ixUnit} '\' folderData(ixFldr).name];
    %         load([calibDataFullPath '\validationData.mat']);
    %     end
    calibDataFullPath = [basePath '\' unitNumber{ixUnit}];
    load([calibDataFullPath '\validationData.mat']);
    disp(['Unit ' unitNumber{ixUnit}]);
    tempData = [data.framesData.temp];
    lddData = [tempData.ldd];
    minLdd = floor(min(lddData));
    maxLdd = ceil(max(lddData));
    crnrPts = nan(numel(tempData),size(data.framesData(1).ptsWithZ,1),2);
    for iTemps = 1:numel(tempData)
        crnrPts(iTemps,:,:) = data.framesData(iTemps).ptsWithZ(:,9:10);
    end
    
    
    %%
    tempDiff = 1;
    tempRngVec = minLdd:tempDiff:maxLdd;
    totalTempRngVec{ixUnit,:} = tempRngVec;
    %     errVec = nan(numel(tempRngVec)-2,1);
    errVec = nan(numel(tempRngVec)-1,1);
    resultsStruct = struct('xRmse',errVec,'xRmseCorrected',errVec,'yRmse',errVec,'yRmseCorrected',errVec,...
        'xMeanAbsErr',errVec,'xMeanAbsErrCorrected',errVec,'yMeanAbsErr',errVec,'yMeanAbsErrCorrected',errVec,...
        'xMaxAbsErr',errVec,'xMaxAbsErrCorrected',errVec,'yMaxAbsErr',errVec,'yMaxAbsErrCorrected',errVec,....
        'scaleCos',errVec,'scaleSin',errVec,'tx',errVec,'ty',errVec);
    resultStructFN = fieldnames(resultsStruct);
    geoTrans = 'nonreflectivesimilarity'; %'projective'
    figure; title(['Unit ' regexprep(unitNumber{ixUnit},'\',' ')]);
    referTempRng = [44,45];%[50 51];
    [matchedPointsMaxTemp] = getMedianPointPerTemp(crnrPts,referTempRng, lddData);
    xVec = errVec;
    %     for k = 1:numel(tempRngVec)-2
    if ixUnit == 1
        thermalFix = struct('T',nan(3,3,numel(tempRngVec)-1),'tempRange',nan(2,numel(tempRngVec)-1),'referenceTempRng',referTempRng);
    end
    for k = 1:numel(tempRngVec)-1
        if tempRngVec(k) == referTempRng(1)
%             for iNames = 1:numel(resultStructFN)
%                 resultsStruct.(resultStructFN{iNames})(k) = [];
%             end
            continue;
        end
        matchedPoints2 = matchedPointsMaxTemp;
        [matchedPoints1] = getMedianPointPerTemp(crnrPts,[tempRngVec(k) tempRngVec(k+1)], lddData);
        xVec(k) = (tempRngVec(k)+tempRngVec(k+1))*0.5;
        ixNotNanBoth = ~isnan(matchedPoints1(:,1)) & ~isnan(matchedPoints2(:,1));
        matchedPoints1 = matchedPoints1(ixNotNanBoth,:);
        matchedPoints2 = matchedPoints2(ixNotNanBoth,:);
        %Calculate errors without fix
        [rmsXyErr,maxAbsXyErr,meanAbsXyErr] = calcErrors(matchedPoints1,matchedPoints2);
        resultsStruct.xRmse(k,1) = rmsXyErr(1);
        resultsStruct.yRmse(k,1) = rmsXyErr(2);
        resultsStruct.xMaxAbsErr(k,1) = maxAbsXyErr(1);
        resultsStruct.yMaxAbsErr(k,1) = maxAbsXyErr(2);
        resultsStruct.xMeanAbsErr(k,1) = meanAbsXyErr(1);
        resultsStruct.yMeanAbsErr(k,1) = meanAbsXyErr(2);
        %Find transformation
        tform = fitgeotrans(matchedPoints1,matchedPoints2, geoTrans);
        if ixUnit == 1
            thermalFix.T(:,:,k) = tform.T;
            thermalFix.tempRange(:,k) = [tempRngVec(k);tempRngVec(k+1)];
        end
        resultsStruct.scaleCos(k,1) = tform.T(1,1);
        resultsStruct.scaleSin(k,1) = tform.T(2,1);
        resultsStruct.tx(k,1) = tform.T(3,1);
        resultsStruct.ty(k,1) = tform.T(3,2);
        % Apply the fix        
        xyCorrect = [matchedPoints1,ones(size(matchedPoints1,1),1)]*tform.T;
        xyCorrect = xyCorrect(:,1:2)./xyCorrect(:,3);
        %Calculate errors after fix
        [rmsXyErr,maxAbsXyErr,meanAbsXyErr] = calcErrors(xyCorrect,matchedPoints2);
        resultsStruct.xRmseCorrected(k,1) = rmsXyErr(1);
        resultsStruct.yRmseCorrected(k,1) = rmsXyErr(2);
        resultsStruct.xMaxAbsErrCorrected(k,1) = maxAbsXyErr(1);
        resultsStruct.yMaxAbsErrCorrected(k,1) = maxAbsXyErr(2);
        resultsStruct.xMeanAbsErrCorrected(k,1) = meanAbsXyErr(1);
        resultsStruct.yMeanAbsErrCorrected(k,1) = meanAbsXyErr(2);
        %Plot corners:
        newPts = xyCorrect;
        tabplot;
        plot(matchedPoints1(:,1),matchedPoints1(:,2),'+r');
        hold on;
        plot(matchedPoints2(:,1),matchedPoints2(:,2),'+g');
        plot(newPts(:,1),newPts(:,2),'ob');
        legend('Changing temp', 'Reference temp', 'Changing temp tramsformed');
        title({['Unit ' regexprep(unitNumber{ixUnit},'\',' ')],['ldd - Changing temp: [' num2str(tempRngVec(k)) ',' num2str(tempRngVec(k+1)) ']' ', Reference: [' num2str(referTempRng(1)) ',' num2str(referTempRng(2)) ']']});
        grid minor;
    end
    
    resultT = struct2table(resultsStruct);
    %Plot errors
    plotErrors(resultsStruct,xVec,tempDiff,unitNumber{ixUnit},referTempRng);
    figure(151285);
    subplot(2,2,1); plot(xVec,resultsStruct.scaleCos); title('Scale*cosine parameter'); hold on;
    subplot(2,2,2); plot(xVec,resultsStruct.scaleSin); title('Scale*sine parameter'); hold on;
    subplot(2,2,3); plot(xVec,resultsStruct.tx); title('Translation x parameter'); hold on;
    subplot(2,2,4); plot(xVec,resultsStruct.ty); title('Translation y parameter'); hold on;
    legendVals{ixUnit} = regexprep(unitNumber{ixUnit},'\',' ');
end
figure(151285);
subplot(2,2,1); legend(legendVals);grid minor;
subplot(2,2,2); legend(legendVals);grid minor;
subplot(2,2,3); legend(legendVals);grid minor;
subplot(2,2,4); legend(legendVals);grid minor;

%%

function [rmsXyErr,maxAbsXyErr,meanAbsXyErr] = calcErrors(pts1,pts2)
errVec = pts2-pts1;
rmsXyErr = rms(errVec);
maxAbsXyErr = max(abs(errVec));
meanAbsXyErr = mean(abs(errVec));
end


function [ptsMed] = getMedianPointPerTemp(pts,tempRng, tempVec)
ixTemp = tempVec>tempRng(1) & tempVec<=tempRng(2);
ptsInTempRng = pts(ixTemp,:,:);
ptsMed = squeeze(median(ptsInTempRng,1));
end


function [] = plotErrors(resultsStruct,xVec,tempDiff,unitNum,referTempRng)
figure;
subplot(3,2,1);hold on; grid minor;
title(['X RMSE compared to max temperature, grouping every ' num2str(tempDiff) ' degree']);
plot(xVec,resultsStruct.xRmse);
plot(xVec,resultsStruct.xRmseCorrected);
legend('xRmse','xRmseCorrected');

subplot(3,2,2);hold on; grid minor;
title({['Unit ' regexprep(unitNum,'\',' ')],['Y RMSE compared to reference temperature: [' num2str(referTempRng(1)) ',' num2str(referTempRng(2)) '] , grouping every ' num2str(tempDiff) ' degree']});
plot(xVec,resultsStruct.yRmse);
plot(xVec,resultsStruct.yRmseCorrected);
legend('yRmse','yRmseCorrected');

subplot(3,2,3);hold on; grid minor;
title({['Unit ' regexprep(unitNum,'\',' ')],['X max absolute error compared to reference temperature: [' num2str(referTempRng(1)) ',' num2str(referTempRng(2)) '] ,  grouping every ' num2str(tempDiff) ' degree']});
plot(xVec,resultsStruct.xMaxAbsErr);
plot(xVec,resultsStruct.xMaxAbsErrCorrected);
legend('xMaxAbsErr','xMaxAbsErrCorrected');

subplot(3,2,4);hold on; grid minor;
title({['Unit ' regexprep(unitNum,'\',' ')],['Y max absolute error compared to reference temperature: [' num2str(referTempRng(1)) ',' num2str(referTempRng(2)) '] ,  grouping every ' num2str(tempDiff) ' degree']});
plot(xVec,resultsStruct.yMaxAbsErr);
plot(xVec,resultsStruct.yMaxAbsErrCorrected);
legend('yMaxAbsErr','yMaxAbsErrCorrected');

subplot(3,2,5);hold on; grid minor;
title({['Unit ' regexprep(unitNum,'\',' ')],['X mean absolute error compared to reference temperature: [' num2str(referTempRng(1)) ',' num2str(referTempRng(2)) '] ,  grouping every ' num2str(tempDiff) ' degree']});
plot(xVec,resultsStruct.xMeanAbsErr);
plot(xVec,resultsStruct.xMeanAbsErrCorrected);
legend('xMeanAbsErr','xMeanAbsErrCorrected');

subplot(3,2,6);hold on; grid minor;
title({['Unit ' regexprep(unitNum,'\',' ')],['Y mean absolute error compared to reference temperature: [' num2str(referTempRng(1)) ',' num2str(referTempRng(2)) '] ,  grouping every ' num2str(tempDiff) ' degree']});
plot(xVec,resultsStruct.yMeanAbsErr);
plot(xVec,resultsStruct.yMeanAbsErrCorrected);
legend('yMeanAbsErr','yMeanAbsErrCorrected');
end

