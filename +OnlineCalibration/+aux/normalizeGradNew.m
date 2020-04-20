function [meanDrDVar] = normalizeGradNew(params,frame,derivVar)
dist = 1500;
Z = single(params.zMaxSubMM)*ones(size(frame.z(:,:,1)))*dist;
V3 = OnlineCalibration.aux.z2vertices(Z,true(size(Z)),params); %logical(ones(size(Z)))
V4 = [V3, ones(size(V3,1),1)];
[dXoutDVar,dYoutDVar,dXinDVar,dYinDVar] = OnlineCalibration.aux.calcValFromExpressions(derivVar,V4,params);
switch derivVar
    case 'P'
        r = sqrt(dXoutDVar.^2+dYoutDVar.^2);
        meanDrDVar = reshape(nanmean(r,2),4,3)';
    case 'R'
        rXalpha = sqrt(dXoutDVar.xAlpha.^2+dYoutDVar.xAlpha.^2);
        rYbeta = sqrt(dXoutDVar.yBeta.^2+dYoutDVar.yBeta.^2);
        rZgamma = sqrt(dXoutDVar.zGamma.^2+dYoutDVar.zGamma.^2);
        meanDrDVar = [nanmean(rXalpha);nanmean(rYbeta);nanmean(rZgamma)];
    case 'T'
        r = sqrt(dXoutDVar.^2+dYoutDVar.^2);
        meanDrDVar = reshape(nanmean(r,2),1,3)';
    case 'Krgb'
        r = sqrt(dXoutDVar.^2+dYoutDVar.^2);
        meanDrDVar = reshape(nanmean(r,2),3,3)';
    case 'Kdepth'
        rfx = sqrt(dXoutDVar.fx.^2+dYoutDVar.fx.^2);
        rfy = sqrt(dXoutDVar.fy.^2+dYoutDVar.fy.^2);
        rox = sqrt(dXoutDVar.ox.^2+dYoutDVar.ox.^2);
        roy = sqrt(dXoutDVar.oy.^2+dYoutDVar.oy.^2);
        meanDrDVar = [nanmean(rfx);nanmean(rfy);nanmean(rox);nanmean(roy)];
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

