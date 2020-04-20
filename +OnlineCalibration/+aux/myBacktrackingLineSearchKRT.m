function [stepSize,newKRTP,newCost] = myBacktrackingLineSearchKRT(frame,params,gradStruct)
% maxStepSize,tau,controlParam,gradStruct,params,V,W,D)
% A search scheme based on the Armijo–Goldstein condition to determine the
% maximum amount to move along a given search direction.
% For more details see: https://en.wikipedia.org/wiki/Backtracking_line_search
grad = [gradStruct.xAlpha;gradStruct.yBeta;gradStruct.zGamma;gradStruct.T;gradStruct.Krgb(:)];
grad = grad./norm(grad)./[params.RnormalizationParams;params.TmatNormalizationMat;params.KrgbMatNormalizationMat(:)];

unitGrad = grad./norm(grad);
stepSize = params.maxStepSize*norm(grad)/norm(unitGrad);

t = -params.controlParam*grad(:)'*unitGrad(:);

RrgbNew = OnlineCalibration.aux.calcRmatRromAngs(params.xAlpha+stepSize*unitGrad(1),params.yBeta+stepSize*unitGrad(2),params.zGamma+stepSize*unitGrad(3));
TrgbNew = params.Trgb + stepSize*unitGrad(4:6);
KrgbNew = params.Krgb + stepSize*reshape(unitGrad(7:end),3,3);

paramsNew = params;
paramsNew.rgbPmat = KrgbNew*[RrgbNew,TrgbNew];
paramsNew.Krgb = KrgbNew;
if params.constLastLineOfP
    paramsNew.rgbPmat(3,:) = params.rgbPmat(3,:);
end

[cost1,~,u1] = OnlineCalibration.aux.calculateCost(frame.vertices,frame.weights,frame.rgbIDT,params);
[cost2,~,u2] = OnlineCalibration.aux.calculateCost(frame.vertices,frame.weights,frame.rgbIDT,paramsNew);
if isfield(params,'showOptProgress') && params.showOptProgress
    figure(190788)
    tabplot;
    imagesc(frame.rgbIDT);
    hold on
    quiver(u1(:,1)+1,u1(:,2)+1,u2(:,1)-u1(:,1),u2(:,2)-u1(:,2),'r')
%     plot([u1(:,1)+1],[u1(:,2)+1],'or')
%     plot([u1(:,1)+1;u2(:,1)+1],[u1(:,2)+1;u2(:,2)+1],'r','linewidth',2)
%     axis([u1(:,1)-30,u1(:,1)+30,u1(:,2)-30,u1(:,2)+30 ])
    costDebug(1) = cost2;
    alphaDebug(1) = stepSize;
end

% costDebug(1) = cost2;
% alphaDebug(1) = stepSize;

iterCount = 0;
while cost1-cost2 >= stepSize*t && abs(stepSize) > params.minStepSize && iterCount < params.maxBackTrackIters
    
    iterCount = iterCount + 1;
%     disp(['myBacktrackingLineSearch: iteration #: ' num2str(iterCount)]);
    stepSize = params.tau*stepSize;
    RrgbNew = OnlineCalibration.aux.calcRmatRromAngs(params.xAlpha+stepSize*unitGrad(1),params.yBeta+stepSize*unitGrad(2),params.zGamma+stepSize*unitGrad(3));
    TrgbNew = params.Trgb + stepSize*unitGrad(4:6);
    KrgbNew = params.Krgb + stepSize*reshape(unitGrad(7:end),3,3);
    
    paramsNew.rgbPmat = KrgbNew*[RrgbNew,TrgbNew];
    paramsNew.Krgb = KrgbNew;
    if params.constLastLineOfP
        paramsNew.rgbPmat(3,:) = params.rgbPmat(3,:);
    end
    cost2 = OnlineCalibration.aux.calculateCost(frame.vertices,frame.weights,frame.rgbIDT,paramsNew);
    %     costDebug(iterCount+1) = cost2;
    %     alphaDebug(iterCount+1) = stepSize;
    assert( ~isnan(cost2),'Cost shouldn''t be none!');
end

if cost1-cost2 >= stepSize*t
    stepSize = 0;
    newKRTP.P = params.rgbPmat;
    newKRTP.Krgb = params.Krgb;
    newKRTP.Trgb = params.Trgb;
    newKRTP.Rrgb = params.Rrgb;
    newCost = cost1;
else
    newKRTP.P = paramsNew.rgbPmat;
    newKRTP.Krgb = KrgbNew;
    newKRTP.Trgb = TrgbNew;
    newKRTP.Rrgb = RrgbNew;
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

