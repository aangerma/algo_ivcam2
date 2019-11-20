function [Extrinsic,camsAnalysis] = calibrateExtrinsic(camsData,calibParams)
Extrinsic=[];
camsAnalysis=cell(size(camsData)) ; Extrinsic=cell(size(camsData));
if(calibParams.gnrl.verbose)
    mkdirSafe(calibParams.gnrl.outFolder);
end
%% analyze data
for i=1:length(camsData)
    data=camsData{i};
    data.outPath=camsData{i}.outPath;
    if(calibParams.gnrl.verbose)
        mkdirSafe(data.outPath);
    end
    % detect checkres corners
    CB = CBTools.Checkerboard (double(data.Frames(1).i)); 
    camsAnalysis{i}.gridPoints = CB.getGridPointsList;
    camsAnalysis{i}.gridSize = CB.getGridSize;
    vis(data.Frames(1).i,camsAnalysis{i}.gridPoints );
    % convert to point cloud
    camsAnalysis{i}.vert= (Validation.aux.pointsToVertices(camsAnalysis{i}.gridPoints-1, double(data.Frames(1).z), data.params))';
    % detect markers and find offset
    [camsAnalysis{i}.targetOffset] =  Calibration.L520extrinsicCalib.detectMarkersAndFindOffset(calibParams,data,camsAnalysis{i});
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
% projecting per pose to the first camera in pose 
i0=1;
for i=1:length(camsAnalysis)
    if(i==i0)
        Extrinsic{i}.R=eye(3);
        Extrinsic{i}.T=zeros(1,3);
    else
        Extrinsic{i}.R=(camsAnalysis{i}.rotmat)'*camsAnalysis{i0}.rotmat;
        Extrinsic{i}.T=-camsAnalysis{i}.camTranslation*Extrinsic{i}.R+...
            (camsAnalysis{i}.GTtranslation-camsAnalysis{i0}.GTtranslation)*camsAnalysis{i0}.rotmat+camsAnalysis{i0}.camTranslation;
    end
        Extrinsic{i}.from=camsData{i}.camIndexName;
        Extrinsic{i}.to=camsData{i0}.camIndexName; 

end

%% vis
parts = strsplit(camsData{i}.outPath, '\');
poseFolder = fullfile(parts{1:end-1});
if(calibParams.gnrl.verbose)
    h1=figure(); hold all;
    h2=figure(); hold all;    
    Leg1=[];     Leg2=[];    
    for i=1:length(Extrinsic)
        figure(h1);
        origData=camsAnalysis{i}.vert';
        plot3(origData(:,1),origData(:,2),origData(:,3),'*');
        Leg1=[Leg1,{strcat('origData-cam ',num2str(i-1))}];
        
        projectedData=camsAnalysis{i}.vert'*Extrinsic{i}.R+Extrinsic{i}.T;
        plot3(projectedData(:,1),projectedData(:,2),projectedData(:,3),'*')
        Leg1=[Leg1,{strcat('FittedData-cam ',num2str(i-1))}];
        camsAnalysis{i}.fittedData=projectedData;
        figure(h2);plot(camsAnalysis{i}.gtV(1,:),camsAnalysis{i}.gtV(2,:),'*');
        Leg2=[Leg2,{strcat('GT-cb:cam ',num2str(i-1))}];
        
    end
    figure(h1);
    
    legend(Leg1);
    grid minor
    view(67,32);
    title(strcat('projected data- on cam',num2str(camsData{i0}.camIndexName),' axis'));
    saveas(h1,strcat(poseFolder,'/projectedData'));    
    save(strcat(poseFolder,'\Extrinsic'),'Extrinsic');
    
    figure(h2);
    axis ij
    grid minor;
    title('GT - cb');
    legend(Leg2);
    saveas(h2,strcat(poseFolder,'/GT_cb'));    

    
end
end




function []=vis(im,pt )
pointsNum=length(pt);
figure();
imagesc(im); hold on;
scatter(pt(:,1),pt(:,2),'+','MarkerEdgeColor','r','LineWidth',1.5);
txt=split(mat2str(1:pointsNum));
text(pt(:,1)+1,pt(:,2),txt);
end