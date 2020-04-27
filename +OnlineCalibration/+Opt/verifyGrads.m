% For each parameter:
% Calculate the derivative of dx/dp and compare to the result
exampleParamsFn = fullfile(ivcam2root,'+OnlineCalibration','+Opt','exampleParams.mat');
load(exampleParamsFn)

dist = 1500;
Z = single(params.zMaxSubMM)*ones(params.depthRes)*dist;
V = OnlineCalibration.aux.z2vertices(Z,true(size(Z)),params); %logical(ones(size(Z)))
V = [V, ones(size(V,1),1)];

%% Verify P
derivVar = 'P'; % P looks good
[dXoutDVar,dYoutDVar,~,~] = OnlineCalibration.aux.calcValFromExpressions(derivVar,V,params);
dXoutDVar = reshape(dXoutDVar,4,3,[]);
dXoutDVar = permute(dXoutDVar,[2,1,3]);
dXoutDVar = reshape(dXoutDVar,12,[]);
dYoutDVar = reshape(dYoutDVar,4,3,[]);
dYoutDVar = permute(dYoutDVar,[2,1,3]);
dYoutDVar = reshape(dYoutDVar,12,[]);

pixMovement = 0.01;
for i = 1:numel(params.rgbPmat)
    epsilon = pixMovement/params.rgbPmatNormalizationMat(i);
    parMin = params;
    parMin.rgbPmat(i) = parMin.rgbPmat(i) - epsilon;
    parPls = params;
    parPls.rgbPmat(i) = parPls.rgbPmat(i) + epsilon;
    
    [uvMin,~,~] = OnlineCalibration.aux.projectVToRGB(V(:,1:3),parMin.rgbPmat,parMin.Krgb,parMin.rgbDistort,params);
    [uvPls,~,~] = OnlineCalibration.aux.projectVToRGB(V(:,1:3),parPls.rgbPmat,parPls.Krgb,parPls.rgbDistort,params);
    
    dXoutDVarNumerical = (uvPls(:,1)-uvMin(:,1))/(2*epsilon);
    maxDiffX(i) = max(abs(dXoutDVarNumerical - dXoutDVar(i,:)'));
    maxDiffRelativeX(i) = max(abs(dXoutDVarNumerical - dXoutDVar(i,:)'))./mean(abs(dXoutDVar(i,:)));
    dYoutDVarNumerical = (uvPls(:,2)-uvMin(:,2))/(2*epsilon);
    maxDiffY(i) = max(abs(dYoutDVarNumerical - dYoutDVar(i,:)'));
    maxDiffRelativeY(i) = max(abs(dYoutDVarNumerical - dYoutDVar(i,:)'))./mean(abs(dYoutDVar(i,:)));
end
% for i = 1:numel(params.rgbPmat)
%     tabplot(i);
%     histogram(dXoutDVar(i,:));
% end
maxDiffX = reshape(maxDiffX,3,4);
maxDiffX(1:2,:)
maxDiffRelativeX = reshape(maxDiffRelativeX,3,4);
maxDiffRelativeX(1:2,:)% Y has minimal effect on X and vice versa
maxDiffY = reshape(maxDiffY,3,4);
maxDiffY(1:2,:)
maxDiffRelativeY = reshape(maxDiffRelativeY,3,4);
maxDiffRelativeY(1:2,:) % Y has minimal effect on X and vice versa



%% Verify T - Looks good
clear maxDiffX maxDiffY maxDiffRelativeX maxDiffRelativeY
derivVar = 'T'; % P looks good
[dXoutDVar,dYoutDVar,~,~] = OnlineCalibration.aux.calcValFromExpressions(derivVar,V,params);
pixMovement = 0.01;
for i = 1:numel(params.Trgb)
    epsilon = pixMovement/params.TmatNormalizationMat(i);
    parMin = params;
    parMin.Trgb(i) = parMin.Trgb(i) - epsilon;
    parMin.rgbPmat = parMin.Krgb*[parMin.Rrgb,parMin.Trgb];
    parPls = params;
    parPls.Trgb(i) = parPls.Trgb(i) + epsilon;
    parPls.rgbPmat = parPls.Krgb*[parPls.Rrgb,parPls.Trgb];
    
    [uvMin,~,~] = OnlineCalibration.aux.projectVToRGB(V(:,1:3),parMin.rgbPmat,parMin.Krgb,parMin.rgbDistort,params);
    [uvPls,~,~] = OnlineCalibration.aux.projectVToRGB(V(:,1:3),parPls.rgbPmat,parPls.Krgb,parPls.rgbDistort,params);
    
    dXoutDVarNumerical = (uvPls(:,1)-uvMin(:,1))/(2*epsilon);
    maxDiffX(i) = max(abs(dXoutDVarNumerical - dXoutDVar(i,:)'));
    maxDiffRelativeX(i) = max(abs(dXoutDVarNumerical - dXoutDVar(i,:)'))./mean(abs(dXoutDVar(i,:)));
    dYoutDVarNumerical = (uvPls(:,2)-uvMin(:,2))/(2*epsilon);
    maxDiffY(i) = max(abs(dYoutDVarNumerical - dYoutDVar(i,:)'));
    maxDiffRelativeY(i) = max(abs(dYoutDVarNumerical - dYoutDVar(i,:)'))./mean(abs(dYoutDVar(i,:)));
end
% for i = 1:numel(params.rgbPmat)
%     tabplot(i);
%     histogram(dXoutDVar(i,:));
% end
maxDiffX
maxDiffRelativeX% Y has minimal effect on X and vice versa
maxDiffY
maxDiffRelativeY % Y has minimal effect on X and vice versa


%% Verify R - Looks bad
clear maxDiffX maxDiffY maxDiffRelativeX maxDiffRelativeY
derivVar = 'R'; % P looks good
[dXoutDVar,dYoutDVar,~,~] = OnlineCalibration.aux.calcValFromExpressions(derivVar,V,params);
angNames = fieldnames(dXoutDVar);
pixMovement = 0.001;
for i = 1:numel(angNames)
    epsilon = pixMovement/params.RnormalizationParams(i);
    parMin = params;
    parMin.(angNames{i}) = parMin.(angNames{i}) - epsilon;
    parMin.Rrgb = OnlineCalibration.aux.calcRmatRromAngs(parMin.xAlpha,parMin.yBeta,parMin.zGamma);
    parMin.rgbPmat = parMin.Krgb*[parMin.Rrgb,parMin.Trgb];
    parPls = params;
    parPls.(angNames{i}) = parPls.(angNames{i}) + epsilon;
    parPls.Rrgb = OnlineCalibration.aux.calcRmatRromAngs(parPls.xAlpha,parPls.yBeta,parPls.zGamma);
    parPls.rgbPmat = parPls.Krgb*[parPls.Rrgb,parPls.Trgb];
    
    [uvMin,~,~] = OnlineCalibration.aux.projectVToRGB(V(:,1:3),parMin.rgbPmat,parMin.Krgb,parMin.rgbDistort,params);
    [uvPls,~,~] = OnlineCalibration.aux.projectVToRGB(V(:,1:3),parPls.rgbPmat,parPls.Krgb,parPls.rgbDistort,params);
    
    dXoutDVarNumerical = (uvPls(:,1)-uvMin(:,1))/(2*epsilon);
    maxDiffX(i) = max(abs(dXoutDVarNumerical - dXoutDVar.(angNames{i})'));
    maxDiffRelativeX(i) = max(abs(dXoutDVarNumerical - dXoutDVar.(angNames{i})'))./mean(abs(dXoutDVar.(angNames{i})));
    dYoutDVarNumerical = (uvPls(:,2)-uvMin(:,2))/(2*epsilon);
    maxDiffY(i) = max(abs(dYoutDVarNumerical - dYoutDVar.(angNames{i})'));
    maxDiffRelativeY(i) = max(abs(dYoutDVarNumerical - dYoutDVar.(angNames{i})'))./mean(abs(dYoutDVar.(angNames{i})));
end
% for i = 1:numel(params.rgbPmat)
%     tabplot(i);
%     histogram(dXoutDVar(i,:));
% end
maxDiffX
maxDiffRelativeX% Y has minimal effect on X and vice versa
maxDiffY
maxDiffRelativeY % Y has minimal effect on X and vice versa

%% Verfiy Krgb - Debatable
clear maxDiffX maxDiffY maxDiffRelativeX maxDiffRelativeY
derivVar = 'Krgb'; % P looks good
[dXoutDVar,dYoutDVar,~,~] = OnlineCalibration.aux.calcValFromExpressions(derivVar,V,params);
dXoutDVar = reshape(dXoutDVar,3,3,[]);
dXoutDVar = permute(dXoutDVar,[2,1,3]);
dXoutDVar = reshape(dXoutDVar,9,[]);
dYoutDVar = reshape(dYoutDVar,3,3,[]);
dYoutDVar = permute(dYoutDVar,[2,1,3]);
dYoutDVar = reshape(dYoutDVar,9,[]);

pixMovement = 0.01;
for i = 1:numel(params.Krgb)
    epsilon = pixMovement/params.KrgbMatNormalizationMat(i);
    parMin = params;
    parMin.Krgb(i) = parMin.Krgb(i) - epsilon;
    parMin.rgbPmat = parMin.Krgb*[parMin.Rrgb,parMin.Trgb];
    parPls = params;
    parPls.Krgb(i) = parPls.Krgb(i) + epsilon;
    parPls.rgbPmat = parPls.Krgb*[parPls.Rrgb,parPls.Trgb];
    
    [uvMin,~,~] = OnlineCalibration.aux.projectVToRGB(V(:,1:3),parMin.rgbPmat,parMin.Krgb,parMin.rgbDistort,params);
    [uvPls,~,~] = OnlineCalibration.aux.projectVToRGB(V(:,1:3),parPls.rgbPmat,parPls.Krgb,parPls.rgbDistort,params);
    
    dXoutDVarNumerical = (uvPls(:,1)-uvMin(:,1))/(2*epsilon);
    maxDiffX(i) = max(abs(dXoutDVarNumerical - dXoutDVar(i,:)'));
    maxDiffRelativeX(i) = max(abs(dXoutDVarNumerical - dXoutDVar(i,:)'))./mean(abs(dXoutDVar(i,:)));
    dYoutDVarNumerical = (uvPls(:,2)-uvMin(:,2))/(2*epsilon);
    maxDiffY(i) = max(abs(dYoutDVarNumerical - dYoutDVar(i,:)'));
    maxDiffRelativeY(i) = max(abs(dYoutDVarNumerical - dYoutDVar(i,:)'))./mean(abs(dYoutDVar(i,:)));
end
% for i = 1:numel(params.rgbPmat)
%     tabplot(i);
%     histogram(dXoutDVar(i,:));
% end
maxDiffX = reshape(maxDiffX,3,3);
maxDiffX
maxDiffRelativeX = reshape(maxDiffRelativeX,3,3);
maxDiffRelativeX% Y has minimal effect on X and vice versa
maxDiffY = reshape(maxDiffY,3,3);
maxDiffY
maxDiffRelativeY = reshape(maxDiffRelativeY,3,3);
maxDiffRelativeY % Y has minimal effect on X and vice versa


%% Verfiy Kdepth - 
clear maxDiffX maxDiffY maxDiffRelativeX maxDiffRelativeY
derivVar = 'Kdepth'; % P looks good
[dXoutDVar,dYoutDVar,~,~] = OnlineCalibration.aux.calcValFromExpressions(derivVar,V,params);
fNames = fieldnames(dXoutDVar);
inds = [1,5,7,8];
pixMovement = 0.001;
for i = 1:numel(fNames)
    epsilon = pixMovement/params.KdepthMatNormalizationMat(i);
    parMin = params;
    parMin.Kdepth(inds(i)) = parMin.Kdepth(inds(i)) - epsilon;
    Vmin = OnlineCalibration.aux.z2vertices(Z,true(size(Z)),parMin); %logical(ones(size(Z)))
    
    parPls = params;
    parPls.Kdepth(inds(i)) = parPls.Kdepth(inds(i)) + epsilon;
    Vpls = OnlineCalibration.aux.z2vertices(Z,true(size(Z)),parPls); %logical(ones(size(Z)))
    
    [uvMin,~,~] = OnlineCalibration.aux.projectVToRGB(Vmin,parMin.rgbPmat,parMin.Krgb,parMin.rgbDistort,params);
    [uvPls,~,~] = OnlineCalibration.aux.projectVToRGB(Vpls,parPls.rgbPmat,parPls.Krgb,parPls.rgbDistort,params);
    
    dXoutDVarNumerical = (uvPls(:,1)-uvMin(:,1))/(2*epsilon);
    maxDiffX(i) = max(abs(dXoutDVarNumerical - dXoutDVar.(fNames{i})'));
    maxDiffRelativeX(i) = max(abs(dXoutDVarNumerical - dXoutDVar.(fNames{i})'))./mean(abs(dXoutDVar.(fNames{i})));
    dYoutDVarNumerical = (uvPls(:,2)-uvMin(:,2))/(2*epsilon);
    maxDiffY(i) = max(abs(dYoutDVarNumerical - dYoutDVar.(fNames{i})'));
    maxDiffRelativeY(i) = max(abs(dYoutDVarNumerical - dYoutDVar.(fNames{i})'))./mean(abs(dYoutDVar.(fNames{i})));
end
% for i = 1:numel(params.rgbPmat)
%     tabplot(i);
%     histogram(dXoutDVar(i,:));
% end
maxDiffX
maxDiffRelativeX% Y has minimal effect on X and vice versa
maxDiffY
maxDiffRelativeY % Y has minimal effect on X and vice versa

