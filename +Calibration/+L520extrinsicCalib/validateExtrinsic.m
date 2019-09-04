function [results] = validateExtrinsic(Extrinsic,camsData,calibParams)
params = Validation.aux.defaultMetricsParams();
h1=figure(); hold on;
Leg=[];
unionData=[]; 

for i=1:length(camsData)
    
    %% params
    roi=calibParams.validation.roi;
    params.camera=camsData{i}.params;
    params.isRoiRect=1;
    params.roi=roi;
    %% PF - original data
    [results.(strcat('PFrms_origData',num2str(i-1))) , OrigResults{i},Origdbg{i}]=Validation.metrics.planeFit(camsData{i}.Frames,params);
    %% project data
    mask = Validation.aux.getRoiMask(size(camsData{i}.Frames.z), params);
    v{i} = Validation.aux.imgToVertices(camsData{i}.Frames.z, params.camera, mask);
    fittedData{i}=v{i}*Extrinsic{i}.R+Extrinsic{i}.T;
    plot3(v{i}(:,1),v{i}(:,2),v{i}(:,3),'*');
    Leg=[Leg,{strcat('origData-cam ',num2str(i-1))}];
    
    plot3(fittedData{i}(:,1),fittedData{i}(:,2),fittedData{i}(:,3),'*');
    Leg=[Leg,{strcat('FittedData-cam ',num2str(i-1))}];
    
    %% PF - for each camera + union data
    [results.(strcat('PFrms_fittedData',num2str(i-1))) , fittedDataResults{i},fittedDatadbg{i}]=Validation.metrics.planeFitOnVerts(fittedData{i});
    unionData=[unionData; fittedData{i}]; 
end
    legend(Leg);
    grid minor
    view(67,32);
    [results.PFrms_unionFittedData, unionDataResults,unionDatadbg]=Validation.metrics.planeFitOnVerts(unionData);
    saveas(h,strcat(calibParams.gnrl.outFolder,'/ValidationProjectedData'));


end

