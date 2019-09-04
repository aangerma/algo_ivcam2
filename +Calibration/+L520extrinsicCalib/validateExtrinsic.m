function [] = validateExtrinsic(Extrinsic,camsData)
params = Validation.aux.defaultMetricsParams();

for i=1:length(camsData)

%% params
roi=1; 
params.camera=camsData{i}.params; 
params.isRoiRect=1;
params.roi=roi; 
%% PF - original data
[~ , OrigResults{i},Origdbg{i}]=Validation.metrics.planeFit(camsData{i}.Frames,params); 
%% project data
mask = Validation.aux.getRoiMask(size(camsData{i}.Frames.z), params);
v{i} = Validation.aux.imgToVertices(camsData{i}.Frames.z, params.camera, mask);
fittedData{i}=v{i}*Extrinsic{i}.R+Extrinsic{i}.T;

%% PF - for each camera + union data
[~ , fittedDataResults{i},fittedDatadbg{i}]=Validation.metrics.planeFit(fittedData{i},params); 

end 
end

