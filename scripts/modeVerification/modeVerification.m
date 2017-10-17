clear
saveData = 1;
scenes = {'Wall','randomCubes'};
testModes = {'HD30',           'HD45',          'HD5',            'HHD45',...
             'SXVGA30',        'SXVGA30F',      'VGA60',          'HVGA100',...
             'VGA30',          'VGA15',         'VGA5',           'QVGA120',...
             'QVGA60',         'QVGA30',        'QVGA15',         'QVGA5',....
             'QVGA30S.5_8',    'QVGA5S.5_8',    'QVGA30S.5_4',    'QVGA5S.5_4',...
             'QVGA30S.25_4_26','QVGA5S.25_4_26','QVGA30S.25_4_52','QVGA5S.25_4_52',...
             'QVGA30S.5_8_64', 'QVGA5S.5_4_104','QVGA30S.5_4_104','QVGA5S.5_4_128',...
             'QVGA30S.25_4_44','QVGA5S.25_4_64'};
%  mainDir = fullfile('\\ger\ec\proj\ha\perc\SA_3DCam\Algorithm\noa\IVCAM2\ModeVerification\ivsFiles');
 mainDir = fullfile('C:\Users\nyedidia\Documents\MATLAB\ivsFiles');
 
 %% Collect Data
 
for j = 1:length(scenes)
    scene = scenes{j};
    outputDir = fullfile(mainDir,scene);
    if saveData
        mkdir(outputDir,'output');
    end

    for i = 1:length(testModes) % 19:length(testModes)

        modeName = testModes{i};
        sceneMode = sprintf('%s-%s',scene,modeName);

        if ~exist(fullfile(outputDir,sceneMode,'patternGenerator.ivs'),'file') ||...
            ~exist(fullfile(outputDir,sprintf('GT-%s',sceneMode),'patternGenerator.ivs'),'file')

            [ivsFilename, GTivsFilename] = setModeRegs(modeName,scene,outputDir);
        else
            ivsFilename = fullfile(outputDir,sceneMode,'patternGenerator.ivs');
            GTivsFilename = fullfile(outputDir,sprintf('GT-%s',sceneMode),'patternGenerator.ivs');
        end

        % Run pipe
        [pipeOutData,regs,~,~] = Pipe.autopipe(ivsFilename);    
        [GTpipeOutData,GTregs,~,~] = Pipe.autopipe(GTivsFilename);

        % save data
        if saveData
            savePath = fullfile(outputDir,'output');
            mkdir(savePath,sceneMode);
            save(fullfile(savePath,sceneMode,sprintf('%s.mat',sceneMode)),...
                'pipeOutData','GTpipeOutData','regs','GTregs');
        end
    end
end

%% Analyze Data

if saveData
    for j = 1:length(scenes)
        scene = scenes{j};
        inputDir = fullfile(mainDir,scene);

        for i = 1:length(testModes)

            modeName = testModes{i};
            try
                analyzeModes(modeName,scene,inputDir)

                ptgIm = imread(fullfile(inputDir,sprintf('%s-%s',scene,modeName),'patternGenerator',...
                    'patternGenerator.png'));
                figure
                imshow(ptgIm)
                title(sprintf('%s-%s',modeName,scene));

                GTptgIm = imread(fullfile(inputDir,sprintf('GT-%s-%s',scene,modeName),'patternGenerator',...
                    'patternGenerator.png'));
                figure
                imshow(GTptgIm)
                title(sprintf('%s-%s - GT',modeName,scene));
            catch
                fprintf('Error in mode %s, scene %s \n',modeName,scene);
            end
            
        end
    end
end

