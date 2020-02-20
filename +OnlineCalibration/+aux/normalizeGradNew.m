function [meanDrDVar] = normalizeGradNew(params,frame,derivVar)
dist = 1500;
Z = single(params.zMaxSubMM)*ones(size(frame.z(:,:,1)))*dist;
V3 = OnlineCalibration.aux.z2vertices(Z,true(size(Z)),params); %logical(ones(size(Z)))
V4 = [V3, ones(size(V3,1),1)];
[~,~,dXinDVar,dYinDVar] = OnlineCalibration.aux.calcValFromExpressions(derivVar,V4,params);
switch derivVar
    case 'P'
        r = sqrt(dXinDVar.^2+dYinDVar.^2);
        meanDrDVar = reshape(nanmean(r,2),4,3)';
    case 'R'
        rXalpha = sqrt(dXinDVar.xAlpha.^2+dYinDVar.xAlpha.^2);
        rYbeta = sqrt(dXinDVar.yBeta.^2+dYinDVar.yBeta.^2);
        rZgamma = sqrt(dXinDVar.zGamma.^2+dYinDVar.zGamma.^2);
        meanDrDVar = [nanmean(rXalpha);nanmean(rYbeta);nanmean(rZgamma)];
    case 'T'
        r = sqrt(dXinDVar.^2+dYinDVar.^2);
        meanDrDVar = reshape(nanmean(r,2),1,3)';
    otherwise
            error('No such case!!!');
end
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

