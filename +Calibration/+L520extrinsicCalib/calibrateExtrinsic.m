function [Extrinsic,camsAnalysis] = calibrateExtrinsic(camsData,calibParams)
Extrinsic=[];
originIndex=calibParams.gnrl.originCamera;
camsAnalysis=cell(size(camsData)) ; Extrinsic=cell(size(camsData));
if(calibParams.gnrl.verbose)
    mkdirSafe(calibParams.gnrl.outFolder);
end
%% analyze data
for i=1:length(camsData)
    data=camsData{i};
    data.outPath=strcat(calibParams.gnrl.outFolder,'\cam',num2str(i-1));
    if(calibParams.gnrl.verbose)
        mkdirSafe(data.outPath);
    end
    % detect checkres corners
    [camsAnalysis{i}.gridPoints,camsAnalysis{i}.gridSize] = Validation.aux.findCheckerboard(double(data.Frames(1).i), []);
    % convert to point cloud
    camsAnalysis{i}.vert= (Validation.aux.pointsToVertices(camsAnalysis{i}.gridPoints-1, double(data.Frames(1).z), data.params))';
    % detect markers and find offset
    detectedPointData=struct();
    detectedPointData.detectedGridPointsV=camsAnalysis{i}.vert';
    detectedPointData.CBorig=camsAnalysis{i}.gridPoints(1,:);
    [detectedPointData.HrecRange,detectedPointData.VrecRange,detectedPointData.cbXmargin,detectedPointData.cbYmargin]= calculateCheckersRecRangeSizePix(camsAnalysis{i});
    [camsAnalysis{i}.targetOffset] =  Calibration.L520extrinsicCalib.detectMarkersAndFindOffset(calibParams,data,detectedPointData);
    % build GT checkres
    [camsAnalysis{i}.gtV] =  Calibration.L520extrinsicCalib.buidGTcheckers(camsAnalysis{i}.gridSize,camsAnalysis{i}.targetOffset,calibParams.target.cbSquareSz);
    
    % rigid fit - camera data to GT (CB)
    params.verbose=calibParams.gnrl.verbose;
    params.OutPath=data.outPath;
    %Fit camera data to GT CB: fitP = (p2-t2)*rotmat'+t1;
    [camsAnalysis{i}.err,camsAnalysis{i}.fitted2GTspace,camsAnalysis{i}.rotmat,camsAnalysis{i}.GTtranslation,camsAnalysis{i}.camTranslation]...
        =  Calibration.L520extrinsicCalib.rigidFit(camsAnalysis{i}.gtV',camsAnalysis{i}.vert',params);
end

%% project all data to origin cam axis
i0=calibParams.gnrl.originCamIndex+1;
for i=1:length(camsAnalysis)
    if(i==i0)
        Extrinsic{i}.R=eye(3);
        Extrinsic{i}.T=zeros(1,3);
    else
        Extrinsic{i}.R=(camsAnalysis{i}.rotmat)'*camsAnalysis{i0}.rotmat;
        Extrinsic{i}.T=-camsAnalysis{i}.camTranslation*Extrinsic{i}.R+...
            (camsAnalysis{i}.GTtranslation-camsAnalysis{i0}.GTtranslation)*camsAnalysis{i0}.rotmat+camsAnalysis{i0}.camTranslation;
    end
end

%% vis
if(calibParams.gnrl.verbose)
    h=figure(); hold all;
    Leg=[];
    for i=1:length(Extrinsic)
        origData=camsAnalysis{i}.vert';
        plot3(origData(:,1),origData(:,2),origData(:,3),'*');
        Leg=[Leg,{strcat('origData-cam ',num2str(i-1))}];
        fittedData=camsAnalysis{i}.vert'*Extrinsic{i}.R+Extrinsic{i}.T;
        plot3(fittedData(:,1),fittedData(:,2),fittedData(:,3),'*')
        Leg=[Leg,{strcat('FittedData-cam ',num2str(i-1))}];
        camsAnalysis{i}.fittedData=fittedData;
    end
    legend(Leg);
    grid minor
    view(67,32);
    title(strcat('projected data- on cam',num2str(i0-1),' axis'));
    saveas(h,strcat(calibParams.gnrl.outFolder,'/projectedData'));
    
    save(strcat(calibParams.gnrl.outFolder,'\Extrinsic'),'Extrinsic'); 
end
end


function[HrecRange,VrecRange,cbXmargin,cbYmargin]= calculateCheckersRecRangeSizePix(camsAnalysis)
x=camsAnalysis.gridPoints(:,1); y=camsAnalysis.gridPoints(:,2);
X=reshape(x,camsAnalysis.gridSize); Y=reshape(y,camsAnalysis.gridSize);
dx=mean(diff(X'));
HrecRange=[min(dx), max(dx)];
dy=mean(diff(Y)');
VrecRange=[min(dy), max(dy)];
cbXmargin=[max(X(:,1)),min(X(:,end))]; 
cbYmargin=[max(Y(1,:)),min(Y(end,:))]; 
end