function [] = runExtrinsicCalib(imagesFolder,xmlParamsPath)

%% read xml
calibParams = xml2structWrapper(xmlParamsPath);
%% run on each pose
f=dir(imagesFolder);
isdir=[f.isdir];
f=f(isdir);
poseName={f.name};poseName(strcmp(poseName,'.'))=[];poseName(strcmp(poseName,'..'))=[];
poseName=sort(poseName);
PoseNum=length(poseName);
%%
ExtrinsicTable=[];
PosesData={};
for j=1:PoseNum
    %% run on each cam
    PosePath=strcat(imagesFolder,'\',poseName{j});
    f=dir(PosePath);
    isdir=[f.isdir];
    f=f(isdir);
    fname={f.name};fname(strcmp(fname,'.'))=[];fname(strcmp(fname,'..'))=[];
    fname=sort(fname);
    
    %% read frames and intrinsic for each camera
    camsData={} ; % frames + intrinsic for each camera + camera is rotated
    camNum=length(fname);
    skuCamNum=calibParams.gnrl.skuCamsNum;
    for i=1:camNum
        dataPath=strcat(PosePath,'\',fname{i});
        loadK=load(strcat(dataPath,'\Kworld.mat'));
        camsData{i}.params.Kworld=loadK.K;
        try
            loadK=load(strcat(dataPath,'\Kraw.mat'));
            camsData{i}.params.Kraw=loadK.K;
        catch e
        end
        if(skuCamNum==2 && i==1)
            rot=2;
            camsData{i}.params.K=camsData{i}.params.Kraw;
        else
            rot=0;
            camsData{i}.params.K=camsData{i}.params.Kworld;
        end
        name=fname{i};
        camsData{i}.camIndexName= str2num(name(regexp(name,'\d')));
        camsData{i}.origDataAve.i = io.readBinsAndAverage(dataPath, 'I', 'bin',calibParams.camera.calibRes,8);
        camsData{i}.origDataAve.z = io.readBinsAndAverage(dataPath, 'Z', 'bin',calibParams.camera.calibRes,16);
        camsData{i}.Frames.i=rot90(camsData{i}.origDataAve.i,rot);
        camsData{i}.Frames.z=rot90(camsData{i}.origDataAve.z,rot);
        
        
        camsData{i}.params.zMaxSubMM = calibParams.camera.zMaxSubMM;
        camsData{i}.outPath=strcat(calibParams.gnrl.outFolder,'\pose',num2str(j-1),'\cam',num2str(i-1));
    end
    % Rotate images- if needed acording to input
    
    %% cailbrate extrinsic
    PosesData{j}=camsData;
    poseExtrinsic = Calibration.L520extrinsicCalib.calibrateExtrinsic(camsData,calibParams);
    ExtrinsicTable=[ExtrinsicTable,poseExtrinsic{:}];
end
%% transfer all to cam 0
ExtrinsicPerCam={};
cameraOrig=0;
for k=1:skuCamNum
    CamsInds=find([ExtrinsicTable.from]==(k-1));
    TransTo=[ExtrinsicTable(CamsInds).to];
    match2orig=find(TransTo==cameraOrig,1);
    if(~isempty(match2orig)) % transformation to cam 0 exists in ExtrinsicTable
        ExtrinsicPerCam{k}.R=ExtrinsicTable(CamsInds(match2orig(1))).R;
        ExtrinsicPerCam{k}.T=ExtrinsicTable(CamsInds(match2orig(1))).T;
    else % use transformation of prev cam to get to cam0. ex: p2->0=data2*R2->1*R1->0+T2->1*R1->0+T1->0
        prevCam=find(TransTo==k-2,1);
        ExtrinsicPerCam{k}.R=ExtrinsicTable(CamsInds(prevCam(1))).R*ExtrinsicPerCam{k-1}.R;
        ExtrinsicPerCam{k}.T=ExtrinsicTable(CamsInds(prevCam(1))).T*ExtrinsicPerCam{k-1}.R+ExtrinsicPerCam{k-1}.T;
    end
    
end

if skuCamNum==2
    [R180]=ZrotMat(180);
    ExtrinsicPerCam{1}.R=ExtrinsicPerCam{1}.R*R180;
    ExtrinsicPerCam{1}.T=ExtrinsicPerCam{1}.T*R180;
end
%% rot 90 + external origin
if calibParams.gnrl.rot90
    [R90]=ZrotMat(90);
    for i=1:length(ExtrinsicPerCam)
        ExtrinsicPerCam{i}.R=ExtrinsicPerCam{i}.R*R90;
        ExtrinsicPerCam{i}.T=ExtrinsicPerCam{i}.T*R90;
    end
end

if(calibParams.transform2ExternalOrigin.applyT)
    Rext=ocv.Rodrigues(deg2rad(calibParams.transform2ExternalOrigin.ang'));
    for i=1:length(ExtrinsicPerCam)
        ExtrinsicPerCam{i}.R=ExtrinsicPerCam{i}.R*Rext;
        ExtrinsicPerCam{i}.T=ExtrinsicPerCam{i}.T*Rext+calibParams.transform2ExternalOrigin.T;
    end
end

save(strcat(calibParams.gnrl.outFolder,'\ExtrinsicPerCamToCam0'),'ExtrinsicPerCamToCam0');

%% Validate extrinsic
Calibration.L520extrinsicCalib.validateExtrinsic(ExtrinsicPerCam,PosesData,calibParams)
end


function [R]=ZrotMat(theta)
% around z axis
R = [cosd(theta) -sind(theta) 0; sind(theta) cosd(theta) 0 ; 0 0 1];
end

