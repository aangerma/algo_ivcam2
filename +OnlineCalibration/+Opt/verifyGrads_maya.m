% For each parameter:
% Calculate the derivative of dx/dp and compare to the result
% exampleParamsFn = fullfile(ivcam2root,'+OnlineCalibration','+Opt','exampleParams.mat');
exampleParamsFn = "X:\Users\mkiperwa\fromtal\exampleParams.mat";
load(exampleParamsFn)

dist = 1500;
% Z = single(params.zMaxSubMM)*ones(params.depthRes)*dist;
Z = single(params.zMaxSubMM)*ones([12 16])*dist;
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
figureCount = 0;
internCount = 1;
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
    if mod(i,3) == 1
        internCount = 1;
        figure('NumberTitle', 'off', 'Name', ['P' num2str(figureCount+1) '_' num2str(figureCount+3)]);
        figureCount = figureCount + 3;
    end
    titleStr = {['dXoutDVarNumerical ' num2str(i)], ['dXoutDVar ' num2str(i)]};
    plotNumerVsAnalyt(V,dXoutDVarNumerical,dXoutDVar(i,:)',titleStr,[3,4,internCount]);
    titleStr = {['dYoutDVarNumerical ' num2str(i)], ['dYoutDVar '  num2str(i)]};
    plotNumerVsAnalyt(V,dYoutDVarNumerical,dYoutDVar(i,:)',titleStr,[3,4,internCount+2])
    internCount = internCount + 4;
end
sgtitle('P Grad Comparison');

% for i = 1:numel(params.rgbPmat)
%     tabplot(i);
%     histogram(dXoutDVar(i,:));
% end
maxDiffX = reshape(maxDiffX,3,4);
disp('P: maxDiffX');
maxDiffX(1:2,:)
maxDiffRelativeX = reshape(maxDiffRelativeX,3,4);
disp('P: maxDiffRelativeX');
maxDiffRelativeX(1:2,:)% Y has minimal effect on X and vice versa
maxDiffY = reshape(maxDiffY,3,4);
disp('P: maxDiffY');
maxDiffY(1:2,:)
maxDiffRelativeY = reshape(maxDiffRelativeY,3,4);
disp('P: maxDiffRelativeY');
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
disp('T: maxDiffX');
maxDiffX
disp('T: maxDiffRelativeX');
maxDiffRelativeX% Y has minimal effect on X and vice versa
disp('T: maxDiffY');
maxDiffY
disp('T: maxDiffRelativeY');
maxDiffRelativeY % Y has minimal effect on X and vice versa


%% Verify R - Looks bad
clear maxDiffX maxDiffY maxDiffRelativeX maxDiffRelativeY
derivVar = 'R'; % P looks good
[dXoutDVar,dYoutDVar,~,~] = OnlineCalibration.aux.calcValFromExpressions(derivVar,V,params);
angNames = fieldnames(dXoutDVar);
pixMovement = 0.001;
figure('NumberTitle', 'off', 'Name', 'R');
internCount = 1;

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
    
    titleStr = {['dXoutDVarNumerical ' angNames{i}], ['dXoutDVar ' angNames{i}]};
    plotNumerVsAnalyt(V,dXoutDVarNumerical,dXoutDVar.(angNames{i})',titleStr,[numel(angNames),4,internCount]);
    titleStr = {['dYoutDVarNumerical ' angNames{i}], ['dYoutDVar ' angNames{i}]};
    plotNumerVsAnalyt(V,dYoutDVarNumerical,dYoutDVar.(angNames{i})',titleStr,[numel(angNames),4,internCount+2])
    internCount = internCount + 4;
end
sgtitle('R Grad Comparison');

% for i = 1:numel(params.rgbPmat)
%     tabplot(i);
%     histogram(dXoutDVar(i,:));
% end
disp('R: maxDiffX');
maxDiffX
disp('R: maxDiffRelativeX');
maxDiffRelativeX% Y has minimal effect on X and vice versa
disp('R: maxDiffY');
maxDiffY
disp('R: maxDiffRelativeY');
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
disp('Krgb: maxDiffX');
maxDiffX
maxDiffRelativeX = reshape(maxDiffRelativeX,3,3);
disp('Krgb: maxDiffRelativeX');
maxDiffRelativeX% Y has minimal effect on X and vice versa
maxDiffY = reshape(maxDiffY,3,3);
disp('Krgb: maxDiffY');
maxDiffY
maxDiffRelativeY = reshape(maxDiffRelativeY,3,3);
disp('Krgb: maxDiffRelativeY');
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
disp('Kdepth: maxDiffX');
maxDiffX
disp('Kdepth: maxDiffRelativeX');
maxDiffRelativeX% Y has minimal effect on X and vice versa
disp('Kdepth: maxDiffY');
maxDiffY
disp('Kdepth: maxDiffRelativeY');
maxDiffRelativeY % Y has minimal effect on X and vice versa


function [] = plotNumerVsAnalyt(V,numerical,analytic,titleStr,subplotNums)
minColor = min([numerical;analytic]);
maxColor = max([numerical;analytic]);
subplot(subplotNums(1),subplotNums(2),subplotNums(3));scatter3(V(:,1),V(:,1),V(:,2),40,numerical,'filled');
xlabel('x');ylabel('y');zlabel('z');
ax = gca;
ax.XDir = 'reverse';
view(-31,14)
cb = colorbar;
cb.Label.String = titleStr{1};
caxis([minColor maxColor]);
title(titleStr{1});
subplot(subplotNums(1),subplotNums(2),subplotNums(3)+1);scatter3(V(:,1),V(:,1),V(:,2),40, analytic,'filled');
xlabel('x');ylabel('y');zlabel('z');
ax = gca;
ax.XDir = 'reverse';
view(-31,14)
cb = colorbar;
cb.Label.String = titleStr{2};
title(titleStr{2});
caxis([minColor maxColor]);
end
