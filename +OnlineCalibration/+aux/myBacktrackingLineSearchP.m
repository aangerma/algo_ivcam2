function [stepSize,newRgbPmat,newCost] = myBacktrackingLineSearchP(frame,params,gradStruct)
% maxStepSize,tau,controlParam,gradStruct,params,V,W,D)
% A search scheme based on the Armijo–Goldstein condition to determine the
% maximum amount to move along a given search direction.
% For more details see: https://en.wikipedia.org/wiki/Backtracking_line_search
stepSize = params.maxStepSize;
% dfdx = [gradStruct.xAlpha;gradStruct.yBeta;gradStruct.zGamma;gradStruct.T];
grad = gradStruct.P; 


unitGrad = grad./norm(grad);
t = -params.controlParam*grad(:)'*unitGrad(:);

% RrgbNew = OnlineCalibration.aux.calcRmatRromAngs(params.xAlpha+alpha*p(1),params.xBeta+alpha*p(2),params.zGamma+alpha*p(3));
% TrgbNew = params.Trgb+alpha*p(4:end);
% rgbPmatNew = params.Krgb*[RrgbNew,TrgbNew];

paramsNew = params;
paramsNew.rgbPmat = params.rgbPmat + stepSize*unitGrad;
cost1 = OnlineCalibration.aux.calculateCost(frame.vertices,frame.weights,frame.rgbIDT,params);
cost2 = OnlineCalibration.aux.calculateCost(frame.vertices,frame.weights,frame.rgbIDT,paramsNew);

% costDebug(1) = cost2;
% alphaDebug(1) = stepSize;

iterCount = 0;
while cost1-cost2 >= stepSize*t && abs(stepSize) > params.minStepSize && iterCount < params.maxBackTrackIters

    iterCount = iterCount + 1;
    disp(['myBacktrackingLineSearch: iteration #: ' num2str(iterCount)]);
    stepSize = params.tau*stepSize;
%     RrgbNew = OnlineCalibration.aux.calcRmatRromAngs(params.xAlpha+alpha*p(1),params.xBeta+alpha*p(2),params.zGamma+alpha*p(3));
%     TrgbNew = params.Trgb+alpha*p(4:end);
%     rgbPmatNew = params.Krgb*[RrgbNew,TrgbNew];
    paramsNew.rgbPmat = params.rgbPmat + stepSize*unitGrad;
    cost2 = OnlineCalibration.aux.calculateCost(frame.vertices,frame.weights,frame.rgbIDT,paramsNew);
%     costDebug(iterCount+1) = cost2;
%     alphaDebug(iterCount+1) = stepSize;
    assert( ~isnan(cost2),'Cost shouldn''t be none!');
end

if cost1-cost2 >= stepSize*t
    stepSize = 0;
    newRgbPmat = params.rgbPmat;
    newCost = cost1;
else
    newRgbPmat = paramsNew.rgbPmat;
    newCost = cost2;
end

% alphaVec = linspace(0,maxStepSize,100);
% paramsNewDebug = params;
% for k = 1:numel(alphaVec)
% %     R = OnlineCalibration.aux.calcRmatRromAngs(params.xAlpha+alphaVec(k)*p(1),params.xBeta+alphaVec(k)*p(2),params.zGamma+alphaVec(k)*p(3));
% %     T = params.Trgb+alphaVec(k)*p(4:end);
% %     rgbPmatNew = params.Krgb*[R,T];
%     rgbPmatNew = params.rgbPmat + alphaVec(k)*unitGrad;
%     paramsNewDebug.rgbPmat = rgbPmatNew;
%     costFullDebug(k) = OnlineCalibration.aux.calculateCost(V,W,D,paramsNewDebug);
% end
% 
% figure; plot(alphaVec(1:numel(costFullDebug)),costFullDebug); hold on; plot(alphaDebug,costDebug,'+r');
% xlabel('alpha'); ylabel('Cost');
% hold on; plot(alphaVec, -alphaVec*t+costFullDebug(1), 'g');
% grid minor;
end

