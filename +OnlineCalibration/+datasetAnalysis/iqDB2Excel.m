function [] = iqDB2Excel()
basePath = 'X:\Data\IvCam2\OnlineCalibration\Field Tests';
T = readtable(fullfile(basePath,'fieldTestInfo.xlsx'));

counter = 1;
for k = 1:size(T,1)
    scenePath = T.DataLink{k};
    splittedStr = strsplit(scenePath,'Tests\');
    scenePath = fullfile(splittedStr{1},'Tests\Old',splittedStr{2});
    augData = dir(fullfile(scenePath,'iteration*'));
    serialNow = T.SerialNumber{k};
    lightNow = T.Light{k};
    for iAug = 1:numel(augData)
        fileConent = dir(fullfile(scenePath,['iteration' num2str(iAug)],['ac_' num2str(iAug)]));
        %         if numel(fileConent) < 3 % Empty folder
        %             continue;
        %         end
        if ~isfolder(fullfile(scenePath,['iteration' num2str(iAug)],['ac_' num2str(iAug)],'1'))
            continue;
        end
        frameLink{counter,1} = fullfile(scenePath,['iteration' num2str(iAug)],['ac_' num2str(iAug)],'1');
        cameraParamsLink{counter,1} = fullfile(scenePath,['iteration' num2str(iAug)],['iteration' num2str(iAug) '_before']);
        if ~isfolder(fullfile(scenePath,['iteration' num2str(iAug)],['md_' num2str(iAug)]))
            if iAug == 1
                meta.preset = 'NA';
            end
        else
            meta = loadjson(fullfile(scenePath,['iteration' num2str(iAug)],['md_' num2str(iAug)],'md.json'));
        end
        switch meta.preset
            case 'low_ambient'
                preset{counter,1} = 'Short';
            case 'no_ambient'
                preset{counter,1} = 'Long';
            otherwise
                preset{counter,1} = 'NA';
        end
        lutLink{counter,1} = fullfile(basePath,serialNow,'result.csv');
        serial{counter,1} = serialNow;
        light{counter,1} = lightNow;
        scenario{counter,1} = k;
        counter = counter + 1;
    end
end

T = table(frameLink,cameraParamsLink,lutLink,serial,preset,light,scenario);
writeTablePath = OnlineCalibration.datasetAnalysis.getDbPathByType('iq');
writetable(T,writeTablePath);
end