function [] = runExtrinsicCalib(imagesFolder,xmlParamsPath)

%% folder structure - to formalize!
f=dir(imagesFolder); 
isdir=[f.isdir]; 
f=f(isdir);
fname={f.name};
fname(strcmp(fname,'.'))=[];
fname(strcmp(fname,'..'))=[];
fname=sort(fname);
%% read xml
calibParams = xml2structWrapper(xmlParamsPath);
%% read frames and intrinsic for each camera
camsData={} ; % frames + intrinsic for each camera + camera is rotated
camNum=length(fname);

for i=1:camNum
    dataPath=strcat(imagesFolder,'\',fname{i});
    if(camNum==2 && i==1)
        rot=2;
    else 
        rot=0; 
    end        
    AveIrframes = io.readBinsAndAverage(dataPath, 'I', 'bin',calibParams.gnrl.calibRes,8);
    AveZframes = io.readBinsAndAverage(dataPath, 'Z', 'bin',calibParams.gnrl.calibRes,16);
    camsData{i}.Frames.i=rot90(AveIrframes,rot);
    camsData{i}.Frames.z=rot90(AveZframes,rot);
    loadK=load(strcat(dataPath,'\K.mat')); 
    K=loadK.K; 

    camsData{i}.params.K=K; 
    camsData{i}.params.zMaxSubMM = 4;
end
% Rotate images- if needed acording to input

%% cailbrate extrinsic
[Extrinsic,camsAnalysis] = Calibration.L520extrinsicCalib.calibrateExtrinsic(camsData,calibParams);

%% Validate extrinsic
Calibration.L520extrinsicCalib.validateExtrinsic(Extrinsic,camsAnalysis)
end

