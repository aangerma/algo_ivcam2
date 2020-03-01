function [cost,grad] = calcCostAndGrad(frame,params)

    [uvMap,~,~] = OnlineCalibration.aux.projectVToRGB(frame.vertices,params.rgbPmat,params.Krgb,params.rgbDistort);
    
    DVals = interp2(frame.rgbIDT,uvMap(:,1)+1,uvMap(:,2)+1);
    DxVals = interp2(frame.rgbIDTx,uvMap(:,1)+1,uvMap(:,2)+1);
    DyVals = interp2(frame.rgbIDTy,uvMap(:,1)+1,uvMap(:,2)+1);
    
    V = [frame.vertices,ones(size(frame.vertices(:,1)))];
    W = frame.weights;
    if contains(params.derivVar,'P')
        [xCoeffVal,yCoeffVal,~,~] = OnlineCalibration.aux.calcValFromExpressions('P',V,params);
        grad_P = W.*(DxVals.*xCoeffVal' + DyVals.*yCoeffVal');
        grad.P = reshape(nanmean(grad_P),4,3)';
        if params.zeroLastLineOfPGrad
            grad.P(3,:) = 0;
        end
        grad.P = grad.P./norm(grad.P)./params.rgbPmatNormalizationMat;
    end
    if contains(params.derivVar,'T')
        [xCoeffVal,yCoeffVal,~,~] = OnlineCalibration.aux.calcValFromExpressions('T',V,params);
        grad_T = W.*(DxVals.*xCoeffVal' + DyVals.*yCoeffVal');
        grad.T = reshape(nanmean(grad_T),1,3)';
        % TODO - Normalize to pixels
    end
    if contains(params.derivVar,'R')
        [xCoeffVal,yCoeffVal,~,~] = OnlineCalibration.aux.calcValFromExpressions('R',V,params);
        grad_alpha = W.*(DxVals.*xCoeffVal.xAlpha' + DyVals.*yCoeffVal.xAlpha');
        grad.xAlpha = nanmean(grad_alpha);
        grad_beta = W.*(DxVals.*xCoeffVal.yBeta' + DyVals.*yCoeffVal.yBeta');
        grad.yBeta = nanmean(grad_beta);
        grad_gamma = W.*(DxVals.*xCoeffVal.zGamma' + DyVals.*yCoeffVal.zGamma');
        grad.zGamma = nanmean(grad_gamma);
        % TODO - Normalize to pixels
    end
    cost = nanmean(DVals.*W);

    
end

