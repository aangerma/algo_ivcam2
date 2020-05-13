function [cost, grad, iteration_data] = calcCostAndGrad(frame,params)
    [uvMap,~,~] = OnlineCalibration.aux.projectVToRGB(frame.vertices,params.rgbPmat,params.Krgb,params.rgbDistort);
    
    DVals = interp2(double(frame.rgbIDT),double(uvMap(:,1)+1),double(uvMap(:,2)+1));
    DxVals = interp2(double(frame.rgbIDTx),double(uvMap(:,1)+1),double(uvMap(:,2)+1));
    DyVals = interp2(double(frame.rgbIDTy),double(uvMap(:,1)+1),double(uvMap(:,2)+1));
     
    V = [frame.vertices,ones(size(frame.vertices(:,1)))];
    W = frame.weights;
    if contains(params.derivVar,'P')
        [xCoeffVal,yCoeffVal,~,~,x1,y1,rc] = OnlineCalibration.aux.calcValFromExpressions('P',V,params);
        grad_P = W.*(DxVals.*xCoeffVal' + DyVals.*yCoeffVal');
        grad.P = reshape(nanmean(grad_P),4,3)';
        if params.zeroLastLineOfPGrad
            grad.P(3,:) = 0;
        end
        iteration_data.xCoeffValP = xCoeffVal';
        iteration_data.yCoeffValP = yCoeffVal';
        iteration_data.uvmap = uvMap; 
        iteration_data.DVals = DVals;
        iteration_data.DxVals = DxVals;
        iteration_data.DyVals = DyVals;
        iteration_data.calib = params;
        iteration_data.grad = grad;
        iteration_data.x1 = x1;
        iteration_data.y1 = y1;
        iteration_data.rc = rc;
    end
    if contains(params.derivVar,'T')
        [xCoeffVal,yCoeffVal,~,~,x1,y1,rc] = OnlineCalibration.aux.calcValFromExpressions('T',V,params);
        grad_T = W.*(DxVals.*xCoeffVal' + DyVals.*yCoeffVal');
        grad.T = reshape(nanmean(grad_T),1,3)';
        
        iteration_data.xCoeffValT = xCoeffVal';
        iteration_data.yCoeffValT = yCoeffVal';
%         grad.T = zeros(3,1);
    end
    if contains(params.derivVar,'R')
        [xCoeffVal,yCoeffVal,~,~,x1,y1,rc] = OnlineCalibration.aux.calcValFromExpressions('R',V,params);
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
        
        iteration_data.xCoeffValR = xCoeffVal';
        iteration_data.yCoeffValR = yCoeffVal';
        iteration_data.uvmap = uvMap; 
        iteration_data.DVals = DVals;
        iteration_data.DxVals = DxVals;
        iteration_data.DyVals = DyVals;
        iteration_data.calib = params;
        iteration_data.grad = grad;
        iteration_data.x1 = x1;
        iteration_data.y1 = y1;
        iteration_data.rc = rc;
%       grad.xAlpha = 0;
%       grad.yBeta = 0;
%       grad.zGamma = 0;
    end
    if contains(params.derivVar,'Krgb')
        [xCoeffVal,yCoeffVal,~,~, x1,y1,rc] = OnlineCalibration.aux.calcValFromExpressions('Krgb',V,params);
        grad_Krgb = W.*(DxVals.*xCoeffVal' + DyVals.*yCoeffVal');
        grad.Krgb = reshape(nanmean(grad_Krgb),3,3)';
        grad.Krgb(1,2) = 0;
        grad.Krgb(2,1) = 0;
        grad.Krgb(3,1:3) = 0;
%         grad.Krgb = zeros(3,3);

        iteration_data.xCoeffValKrgb = xCoeffVal';
        iteration_data.yCoeffValKrgb = yCoeffVal';
        iteration_data.uvmap = uvMap; 
        iteration_data.DVals = DVals;
        iteration_data.DxVals = DxVals;
        iteration_data.DyVals = DyVals;
        iteration_data.calib = params;
        iteration_data.grad = grad;
        iteration_data.grad.Rrgb = OnlineCalibration.aux.calcRmatRromAngs(grad.xAlpha,grad.yBeta,grad.zGamma);
        iteration_data.x1 = x1;
        iteration_data.y1 = y1;
        iteration_data.rc = rc;
    end
    cost = nanmean(DVals.*W);

    
end
