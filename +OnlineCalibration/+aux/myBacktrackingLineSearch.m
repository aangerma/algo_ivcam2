function [alpha] = myBacktrackingLineSearch(max_step_size,tau,controlParam,gradStruct,params,V,W,D)
% A search scheme based on the Armijo–Goldstein condition to determine the
% maximum amount to move along a given search direction.
% For more details see: https://en.wikipedia.org/wiki/Backtracking_line_search
if ~exist('tau','var')
    tau = 0.5;
end
if ~exist('cParam','var')
    controlParam = 0.5;
end
alpha = max_step_size;

% dfdx = [gradStruct.xAlpha;gradStruct.yBeta;gradStruct.zGamma;gradStruct.T];
dfdx = gradStruct.A;

iterCount = 0;
p = dfdx./norm(dfdx);
t = -controlParam*dfdx(:)'*p(:);

% RrgbNew = OnlineCalibration.aux.calcRmatRromAngs(params.xAlpha+alpha*p(1),params.xBeta+alpha*p(2),params.zGamma+alpha*p(3));
% TrgbNew = params.Trgb+alpha*p(4:end);
% rgbPmatNew = params.Krgb*[RrgbNew,TrgbNew];
rgbPmatNew = params.rgbPmat + alpha*p;

paramsNew = params;
paramsNew.rgbPmat = rgbPmatNew;
cost1 = OnlineCalibration.aux.calculateCost(V,W,D,params);
cost2 = OnlineCalibration.aux.calculateCost(V,W,D,paramsNew);
%%
% Debug:
%{
tau = 0.99;
x = -50;
y = x;
b = 0;
alpha = 100;
dfdx = [-2*x; -2*y];
iterCount = 0;
p = dfdx./norm(dfdx);
t = -controlParam*dfdx'*p;
cost1 = -x.^2-(y.^2)+b;
cost2 =-(x+alpha*p(1)).^2-(y+alpha*p(2)).^2;
xVec = max(x*alpha*p(1),x):1:-max(x*alpha*p(1),x); yVec = xVec; zVec = -(xVec.^2)-(yVec.^2)+b; figure; plot3(xVec,yVec,zVec);grid minor; xlabel('x'); ylabel('y'); zlabel('z');
hold on; plot3(x,y,cost1,'g+');
hold on; plot3(x+alpha*p(1),y+alpha*p(2),cost2,'b+');
plot3(xVec,yVec,sqrt(sum(([xVec;yVec]-[x;y]).^2))*(-t)+(-(x.^2)-(y.^2)+b), 'r');
while cost1-cost2 >= alpha*t
    iterCount = iterCount + 1;
    alpha = tau*alpha;
    cost2 =-(x+alpha*p(1)).^2-(y+alpha*p(2)).^2+b;
    hold on; plot3(x+alpha*p(1),y+alpha*p(2),cost2,'r+');
end
%}
%%
costDebug(1) = cost2;
alphaDebug(1) = alpha;

while isnan(cost2) || cost1-cost2 >= alpha*t && abs(alpha) > 10e-5 
    iterCount = iterCount + 1;
    disp(['myBacktrackingLineSearch: iteration #: ' num2str(iterCount)]);
    alpha = tau*alpha;
%     RrgbNew = OnlineCalibration.aux.calcRmatRromAngs(params.xAlpha+alpha*p(1),params.xBeta+alpha*p(2),params.zGamma+alpha*p(3));
%     TrgbNew = params.Trgb+alpha*p(4:end);
%     rgbPmatNew = params.Krgb*[RrgbNew,TrgbNew];
    rgbPmatNew = params.rgbPmat + alpha*p;
    paramsNew.rgbPmat = rgbPmatNew;
    cost2 = OnlineCalibration.aux.calculateCost(V,W,D,paramsNew);
    costDebug(iterCount+1) = cost2;
    alphaDebug(iterCount+1) = alpha;
end

alphaVec = linspace(0,max_step_size,100);
paramsNewDebug = params;
for k = 1:numel(alphaVec)
%     R = OnlineCalibration.aux.calcRmatRromAngs(params.xAlpha+alphaVec(k)*p(1),params.xBeta+alphaVec(k)*p(2),params.zGamma+alphaVec(k)*p(3));
%     T = params.Trgb+alphaVec(k)*p(4:end);
%     rgbPmatNew = params.Krgb*[R,T];
    rgbPmatNew = params.rgbPmat + alphaVec(k)*p;
    paramsNewDebug.rgbPmat = rgbPmatNew;
    costFullDebug(k) = OnlineCalibration.aux.calculateCost(V,W,D,paramsNewDebug);
end

figure; plot(alphaVec(1:numel(costFullDebug)),costFullDebug); hold on; plot(alphaDebug,costDebug,'+r');
xlabel('alpha'); ylabel('Cost');
hold on; plot(alphaVec, -alphaVec*t+costFullDebug(1), 'g');
grid minor;
end

