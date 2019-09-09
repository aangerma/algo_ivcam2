function [results] = validateExtrinsic(Extrinsic,PosesData,calibParams)
params = Validation.aux.defaultMetricsParams();
h1=figure(); hold on;
h2=figure(); hold on;

Leg=[];Leg2=[];
for j=1:length(PosesData)
    camsData=PosesData{j};
    planeOfFittedData={}; fittedData={};
    unionData{j}=[];
    for i=1:length(camsData)
        %% params
        % in validation working on origin data (not rotated)
        camsData{i}.params.K=camsData{i}.params.Kworld;
        Frames=camsData{i}.origDataAve;
        roi=calibParams.validation.roi;
        params.camera=camsData{i}.params;
        params.isRoiRect=1;
        params.roi=roi;
        %% PF - original data
        [results.(strcat('PFrms_origData_pose',num2str(j-1),'_cam',num2str(camsData{i}.camIndexName))) , OrigResults{i},Origdbg{i}]=Validation.metrics.planeFit(Frames,params);
        
        %% project data
        figure(h1);
        mask = Validation.aux.getRoiMask(size(Frames.z), params);
        v{i} = Validation.aux.imgToVertices(Frames.z, params.camera, mask);
        fittedData{i}=v{i}*Extrinsic{camsData{i}.camIndexName+1}.R+Extrinsic{camsData{i}.camIndexName+1}.T;
        plot3(v{i}(:,1),v{i}(:,2),v{i}(:,3),'*');
        Leg=[Leg,{strcat('origData-pose',num2str(j-1),'-cam',num2str(camsData{i}.camIndexName))}];
        
        plot3(fittedData{i}(:,1),fittedData{i}(:,2),fittedData{i}(:,3),'*');
        Leg=[Leg,{strcat('FittedData-pose',num2str(j-1),'-cam',num2str(camsData{i}.camIndexName))}];
        
        figure(h2);
        plot3(fittedData{i}(:,1),fittedData{i}(:,2),fittedData{i}(:,3),'*');
        Leg2=[Leg2,{strcat('FittedData-pose',num2str(j-1),'-cam',num2str(camsData{i}.camIndexName))}];
        
        %% PF - for each camera + union data
        fittedV=fittedData{i};
        [results.(strcat('PFrms_fittedData_pose',num2str(j-1),'_cam',num2str(camsData{i}.camIndexName))) , fittedDataResults{i},fittedDatadbg{i}]=planeFitOnVerts(fittedV);
        p=fittedDatadbg{i}.planeParams;
        planeZ=-fittedV(:,1)*p(1)/p(3)-fittedV(:,2)*p(2)/p(3)+fittedDatadbg{i}.meanZ/p(3);
        planeOfFittedData{i}=[fittedV(:,1),fittedV(:,2),planeZ];
        unionData{j}=[unionData{j};  planeOfFittedData{i}];
    end
end

figure(h1);legend(Leg);grid minor ; view(67,32);
saveas(h1,strcat(calibParams.gnrl.outFolder,'/ValidationFullData'));

figure(h2);legend(Leg2);grid minor ; view(69,-10);
saveas(h2,strcat(calibParams.gnrl.outFolder,'/ValidationProjectedData'));


%% plane fit on union data
for  j=1:length(PosesData)
    unionDataPerPose=unionData{j};
    [score, unionDataResults{j},unionDatadbg{j}]=planeFitOnVerts(unionDataPerPose);
    results.(strcat('PFrms_unionFittedData_pose',num2str(j-1)))=score;
    p=unionDatadbg{j}.planeParams;
    % for view
    [X,Y]=ndgrid(min(unionDataPerPose(:,1)):5:max(unionDataPerPose(:,1)),min(unionDataPerPose(:,2)):0.5:max(unionDataPerPose(:,2)));
    x=X(:); y=Y(:);
    planeZ=-x*p(1)/p(3)-y*p(2)/p(3)+unionDatadbg{j}.meanZ/p(3);
    h3=figure(); hold on;
    plot3(unionDataPerPose(:,1),unionDataPerPose(:,2),unionDataPerPose(:,3),'*');
    plot3(x,y,planeZ,'*');
    grid minor
    view(67,32); title(strcat('PF on union data, RMS=',num2str(score)));
    saveas(h3,strcat(calibParams.gnrl.outFolder,'/ValidationUnionData-pose',num2str(j-1)));
    
    
end

save(strcat(calibParams.gnrl.outFolder,'\PF_results'),'results');
save(strcat(calibParams.gnrl.outFolder,'\unionDatadbg'),'unionDatadbg');
save(strcat(calibParams.gnrl.outFolder,'\fittedDatadbg'),'fittedDatadbg');
end


function [score, results,dbg] = planeFitOnVerts(v)

% vertices 1xN cell array with- Kx3 in each cell- for X,Y,Z verts. (K= points number)
% params : struct

%handle defult outputs
dbg = [];
results = [];

[dist, p,dbg.meanZ] = Validation.metrics.planeFitInternal(v);
results.rmsPlaneFitDist = rms(dist);
results.maxPlaneFitDist = max(abs(dist));
planeParams = p;
dbg.planeParams = planeParams;
results.horizAngle = mean(90-atan2d(planeParams(3),planeParams(1)));
results.verticalAngle = mean(90-atan2d(planeParams(3),planeParams(2)));
score = results.rmsPlaneFitDist;

results.score = 'rmsPlaneFitDist';
results.units = 'mm';
results.error = false;

end
