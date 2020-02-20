function [mean_dr_dVar] = normalizeGradNew(params,frame,derivVar)
dist = 1500;
Z = single(params.zMaxSubMM)*ones(size(frame.z(:,:,1)))*dist;
V = OnlineCalibration.aux.z2vertices(Z,true(size(Z)),params); %logical(ones(size(Z)))
params.V = [V, ones(size(V,1),1)];
params.d = params.rgbDistort;
[~,~,dXin_dVar,dYin_dVar] = OnlineCalibration.aux.calcValFromExpressions(derivVar,params);
r = sqrt(dXin_dVar.^2+dYin_dVar.^2);
mean_dr_dVar = reshape(nanmean(r,2),4,3)';

%%
%{
% debug
eps = 1;
for ix = 1:size(mean_dr_dVar,1)
    for iy =  1:size(mean_dr_dVar,2)
        paramsNew = params;
        paramsNew.rgbPmat(ix,iy) = paramsNew.rgbPmat(ix,iy)+eps;
        pixVecNew = paramsNew.rgbPmat*params.V';
        pixVecOrig =params.rgbPmat*params.V';
        
        drPix = mean(sqrt((pixVecNew(1,:)./pixVecNew(3,:)-pixVecOrig(1,:)./pixVecOrig(3,:)).^2+(pixVecNew(2,:)./pixVecNew(3,:)-pixVecOrig(2,:)./pixVecOrig(3,:)).^2));
        
        if abs(drPix/eps-mean_dr_dVar(ix,iy))/mean_dr_dVar(ix,iy) > 10e-4
            warning(['Problem with normaliztion in variable in position (' num2str(ix) ',' num2str(iy) ')!!! Difference = ' num2str(abs(drPix/eps-mean_dr_dVar(ix,iy))) ',ratio = ' num2str(abs(drPix/eps-mean_dr_dVar(ix,iy))/mean_dr_dVar(ix,iy) )]);
            warning(['drPix = ' num2str(drPix/eps) ', mean_dr_dVar(ix,iy) = ' num2str(mean_dr_dVar(ix,iy))]);

        end
    end
end
%}
end

