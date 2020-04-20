function [cost,grad] = calcCostAndGrad(frame,params)
    if contains(params.derivVar,'Kdepth')
        vertices = ([frame.xim,frame.yim,ones(size(frame.yim))] * pinv(params.Kdepth)').*frame.vertices(:,3);
        [uvMap,~,~] = OnlineCalibration.aux.projectVToRGB(vertices,params.rgbPmat,params.Krgb,params.rgbDistort);
        V = [vertices,ones(size(vertices(:,1)))];
    else
        [uvMap,~,~] = OnlineCalibration.aux.projectVToRGB(frame.vertices,params.rgbPmat,params.Krgb,params.rgbDistort);
        V = [frame.vertices,ones(size(frame.vertices(:,1)))];
    end
    DVals = interp2(frame.rgbIDT,uvMap(:,1)+1,uvMap(:,2)+1);
    DxVals = interp2(frame.rgbIDTx,uvMap(:,1)+1,uvMap(:,2)+1);
    DyVals = interp2(frame.rgbIDTy,uvMap(:,1)+1,uvMap(:,2)+1);
    
    W = frame.weights;
    if contains(params.derivVar,'P')
        [xCoeffVal,yCoeffVal,~,~] = OnlineCalibration.aux.calcValFromExpressions('P',V,params);
        grad_P = W.*(DxVals.*xCoeffVal' + DyVals.*yCoeffVal');
        grad.P = reshape(nanmean(grad_P,1),4,3)';
        if params.zeroLastLineOfPGrad
            grad.P(3,:) = 0;
        end
%         grad.P(1,1) = 0;
%         grad.P(2,2) = 0;
    end
    if contains(params.derivVar,'T')
        [xCoeffVal,yCoeffVal,~,~] = OnlineCalibration.aux.calcValFromExpressions('T',V,params);
        grad_T = W.*(DxVals.*xCoeffVal' + DyVals.*yCoeffVal');
        grad.T = reshape(nanmean(grad_T,1),1,3)';
%         grad.T = zeros(3,1);
        if isfield(params,'AC2') && params.AC2
            grad.T(3) = 0;
        end
    end
    if contains(params.derivVar,'R')
        [xCoeffVal,yCoeffVal,~,~] = OnlineCalibration.aux.calcValFromExpressions('R',V,params);
        grad_alpha = W.*(DxVals.*xCoeffVal.xAlpha' + DyVals.*yCoeffVal.xAlpha');
        grad.xAlpha = nanmean(grad_alpha);
        grad_beta = W.*(DxVals.*xCoeffVal.yBeta' + DyVals.*yCoeffVal.yBeta');
        grad.yBeta = nanmean(grad_beta);
        grad_gamma = W.*(DxVals.*xCoeffVal.zGamma' + DyVals.*yCoeffVal.zGamma');
        grad.zGamma = nanmean(grad_gamma);
        angGradVec = [grad.xAlpha; grad.yBeta; grad.zGamma];
        grad.xAlpha = angGradVec(1);
        grad.yBeta = angGradVec(2);
        grad.zGamma = angGradVec(3);
%         grad.xAlpha = 0;
%         grad.yBeta = 0;
%         grad.zGamma = 0;
        if isfield(params,'AC2') && params.AC2
            grad.xAlpha = 0;
            grad.yBeta = 0;
            grad.zGamma = 0;
        end
    end
    if contains(params.derivVar,'Krgb')
        [xCoeffVal,yCoeffVal,~,~] = OnlineCalibration.aux.calcValFromExpressions('Krgb',V,params);
        grad_Krgb = W.*(DxVals.*xCoeffVal' + DyVals.*yCoeffVal');
        grad.Krgb = reshape(nanmean(grad_Krgb),3,3)';
        grad.Krgb(1,2) = 0;
        grad.Krgb(2,1) = 0;
        grad.Krgb(3,1:3) = 0;

        if isfield(params,'AC2') && params.AC2
            grad.Krgb = reshape(nanmean(grad_Krgb),3,3)';
            grad.Krgb(3,1:3) = 0;
        end
    end
    if contains(params.derivVar,'Kdepth')
        [xCoeffVal,yCoeffVal,~,~] = OnlineCalibration.aux.calcValFromExpressions('Kdepth',V,params);
        grad_fx = W.*(DxVals.*xCoeffVal.fx' + DyVals.*yCoeffVal.fx');
        grad_fy = W.*(DxVals.*xCoeffVal.fy' + DyVals.*yCoeffVal.fy');
        grad_ox = W.*(DxVals.*xCoeffVal.ox' + DyVals.*yCoeffVal.ox');
        grad_oy = W.*(DxVals.*xCoeffVal.oy' + DyVals.*yCoeffVal.oy');
        grad.Kdepth = nanmean([grad_fx,grad_fy,grad_ox,grad_oy],1)';
%         if isfield(params,'debug') && params.debug
%             grad.Kdepth(1:4) = 0;
%         end
        grad.Kdepth(3:4) = 0;
    end
    cost = nanmean(DVals.*W);

    
end

