function [] = runExtrinsicCalib(imagesFolder,xmlParamsPath)

%% folder structure - to formalize!
f=dir(imagesFolder); 
isdir=[f.isdir]; 
f=f(isdir);
fname={f.name};
fname(strcmp(fname,'.'))=[];
fname(strcmp(fname,'..'))=[];
fname=sort(fname);

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
    camsData{i}.Frames.i=rot90(du.formats.readBinFile(strcat(dataPath,'\I_152x232_0000.bin') ,[152 232],8),rot);
    camsData{i}.Frames.z=rot90(du.formats.readBinFile(strcat(dataPath,'\Z_152x232_0000.bin') ,[152 232],16),rot);
    loadK=load(strcat(dataPath,'\K.mat')); 
    K=loadK.K; 
%      K([1 2],:)= K([2 1],:); 
%      K(:,[1,2])= K(:,[2,1]); 

    camsData{i}.params.K=K; 
    camsData{i}.params.zMaxSubMM = 4;
end
% Rotate images- if needed acording to input
%% read xml
calibParams = xml2structWrapper(xmlParamsPath);
[outResults] = Calibration.L520extrinsicCalib.calibrateExtrinsic(camsData,calibParams);
end

