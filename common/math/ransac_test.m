 rng(0)
generateModel = @(x) [x(:,1),ones(size(x,1),1)]\x(:,2);
generateERR = @(th,x)  x(:,2)-([x(:,1),ones(size(x,1),1)]*th);


N_PTS = 1000; %num of samples
P_INLIERS = 0.5; %precentage (out of 1) of samples that fit the model
TH_GT=[0.1;0.2]; %y = TH_GT(1)*x +TH_GT(2)
SIG_ERR = 0; %noise on linear fit

%random y samples on t axis
t = linspace(0,10,N_PTS);
y = rand(size(t))*max(t);

% make some of the samples fit the linear fit
inliers_GT = randperm(length(t),round(length(t)*P_INLIERS));
y(inliers_GT)= t(inliers_GT)*TH_GT(1)+TH_GT(2)+randn(size(inliers_GT))*SIG_ERR;
X = [t;y]';

%ransac on the samples
[bestInlies,bestModel] =ransac(X,generateModel,generateERR,'iterations',900,'errorThr',0.01,'plotFunc','on');

