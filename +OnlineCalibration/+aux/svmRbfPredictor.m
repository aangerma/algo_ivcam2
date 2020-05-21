function labels = svmRbfPredictor(SVMModel, featuresMat)
    % Implementation of Matlab's predict function
    % feturesMat - input samples, should be 2D matrix of size [#samples,
    % data dimensionality]. LibRealSense can assume #samples is always 1.
    % labels - classification labeling (0 - negative,1 - positive)
    
    % Extracting model parameters
    mu = SVMModel.Mu;
    sigma = SVMModel.Sigma;
    xSV = SVMModel.SupportVectors;
    ySV = SVMModel.SupportVectorLabels;
    alpha = SVMModel.Alpha;
    bias = SVMModel.Bias;
    gamma = 1/SVMModel.KernelParameters.Scale^2;
    
    % Applying the model
    xNorm = (featuresMat-mu)./sigma;
    nSamples = size(featuresMat,1);
    labels = zeros(nSamples,1);
    for iSample = 1:nSamples
        innerProduct = exp(-gamma * sum((xNorm(iSample,:) - xSV).^2, 2));
        score = sum(alpha .* ySV .* innerProduct, 1) + bias;
        labels(iSample) = score > 0; % dealing with the theoretical possibility of score=0
    end
end