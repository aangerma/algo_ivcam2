function [stepSize,newRgbPmat,newKrgb,newRrgb,newTrgb,newCost,unitGrad,grad,grads_norm,norma,BacktrackingLineIterCount,t] = myBacktrackingLineSearchP(frame,params,gradStruct)
% maxStepSize,tau,controlParam,gradStruct,params,V,W,D)
% A search scheme based on the Armijo–Goldstein condition to determine the
% maximum amount to move along a given search direction.
% For more details see: https://en.wikipedia.org/wiki/Backtracking_line_search
% dfdx = [gradStruct.xAlpha;gradStruct.yBeta;gradStruct.zGamma;gradStruct.T];
grads_norm = gradStruct.P./norm((gradStruct.P(:)'));
grad = gradStruct.P./norm(gradStruct.P)./params.rgbPmatNormalizationMat; 
norma = norm((gradStruct.P(:)'))

unitGrad = grad./norm(grad);
stepSize = params.maxStepSize*norm(grad)/norm(unitGrad);

t = -params.controlParam*grad(:)'*unitGrad(:);

% RrgbNew = OnlineCalibration.aux.calcRmatRromAngs(params.xAlpha+alpha*p(1),params.xBeta+alpha*p(2),params.zGamma+alpha*p(3));
% TrgbNew = params.Trgb+alpha*p(4:end);
% rgbPmatNew = params.Krgb*[RrgbNew,TrgbNew];

paramsNew = params;
paramsNew.rgbPmat = params.rgbPmat + stepSize*unitGrad;
[paramsNew.Krgb,paramsNew.Rrgb,paramsNew.Trgb] = OnlineCalibration.aux.decomposePMat(paramsNew.rgbPmat);

[cost1,scorePerVertex1,uv1] = OnlineCalibration.aux.calculateCost(frame.vertices,frame.weights,frame.rgbIDT,params);
[cost2,scorePerVertex2,uv2] = OnlineCalibration.aux.calculateCost(frame.vertices,frame.weights,frame.rgbIDT,paramsNew);
commonVerts = ~isnan(scorePerVertex1) & ~isnan(scorePerVertex2);
if isfield(params,'showOptProgress') && params.showOptProgress
    figure(190789)
    tabplot;
    imagesc(frame.rgbIDT);
    hold on
    quiver(uv1(:,1)+1,uv1(:,2)+1,uv2(:,1)-uv1(:,1),uv2(:,2)-uv1(:,2),'r')
%     plot([u1(:,1)+1],[u1(:,2)+1],'or')
%     plot([u1(:,1)+1;u2(:,1)+1],[u1(:,2)+1;u2(:,2)+1],'r','linewidth',2)
%     axis([u1(:,1)-30,u1(:,1)+30,u1(:,2)-30,u1(:,2)+30 ])
    costDebug(1) = cost2;
    alphaDebug(1) = stepSize;
end
BacktrackingLineIterCount = 0;
while nanmean(scorePerVertex1(commonVerts))-nanmean(scorePerVertex2(commonVerts)) >= stepSize*t && abs(stepSize) > params.minStepSize && BacktrackingLineIterCount < params.maxBackTrackIters

    BacktrackingLineIterCount = BacktrackingLineIterCount + 1;
%     disp(['myBacktrackingLineSearch: iteration #: ' num2str(BacktrackingLineIterCount)]);
    stepSize = params.tau*stepSize;
%     RrgbNew = OnlineCalibration.aux.calcRmatRromAngs(params.xAlpha+alpha*p(1),params.xBeta+alpha*p(2),params.zGamma+alpha*p(3));
%     TrgbNew = params.Trgb+alpha*p(4:end);
%     rgbPmatNew = params.Krgb*[RrgbNew,TrgbNew];
    paramsNew.rgbPmat = params.rgbPmat + stepSize*unitGrad;
    [paramsNew.Krgb,paramsNew.Rrgb,paramsNew.Trgb] = OnlineCalibration.aux.decomposePMat(paramsNew.rgbPmat);
    [cost2,scorePerVertex2,uv2] = OnlineCalibration.aux.calculateCost(frame.vertices,frame.weights,frame.rgbIDT,paramsNew);
    commonVerts = ~isnan(scorePerVertex1) & ~isnan(scorePerVertex2);

%     costDebug(BacktrackingLineIterCount+1) = cost2;
%     alphaDebug(BacktrackingLineIterCount+1) = stepSize;
    assert( ~isnan(cost2),'Cost shouldn''t be none!');
end

if nanmean(scorePerVertex1(commonVerts))-nanmean(scorePerVertex2(commonVerts)) >= stepSize*t
    stepSize = 0;
    newRgbPmat = params.rgbPmat;
    newKrgb = params.Krgb;
    newRrgb = params.Rrgb;
    newTrgb = params.Trgb;
    newCost = cost1;
else
    newRgbPmat = paramsNew.rgbPmat;
    newKrgb = paramsNew.Krgb;
    newRrgb = paramsNew.Rrgb;
    newTrgb = paramsNew.Trgb;
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

