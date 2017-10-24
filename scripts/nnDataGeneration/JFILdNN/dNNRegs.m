function regsPlusDNN = dNNRegs(regs)
% This function configurate the regs calculated on tensorflow.

%% The weights as extracted from tensorflow:
weight_file_path = 'X:\Data\IvCam2\NN\JFIL\NN_Weights\depth_NN_weights.mat';
weights = load(weight_file_path);
%% Set the weights in the write configuration regs
% Under featureExtrationD:

% Convolution kernels
% Organize the 8 filters as [8,5*5]
num_filters = 8;
kernel_size = 5*5;
featuresKernel = zeros(num_filters,kernel_size);
featuresKernel(1,:) = vec((weights.conf_filter_w));
featuresKernel(2:num_filters,:) = reshape(permute((weights.depth_filters_w),[3,1,2]),num_filters-1,kernel_size);

% Turn from fractions to int8. Scale up the filters and scale down the
% correspond parameter in the first convolution layer:
requiredSum = 128;
maxRegVal = 2^7-1;
featuresKernelSum = sum(featuresKernel,2);
featuresKernelMax = max(abs(featuresKernel),[],2);
scaleFactor = zeros(num_filters,1);
for i = 1:num_filters
    scaleFactor(i) = min(maxRegVal/featuresKernelMax(i),requiredSum/abs(featuresKernelSum(i)));
    scaleFactor(i) = scaleFactor(i)*sign(scaleFactor(i))*sign(featuresKernelSum(i));% Turn the sum of the weight positive after scale
end

featuresKernelScaled = diag(scaleFactor)*featuresKernel;% Scale each kernel row
% scaleFactorSum = sum(featuresKernelScaled,2);;% The filters shouold be multiplied by 128. Bacause they will be normalized by this number later.



fc1_w_scaled = [weights.fc1_w(1:14,:); diag(featuresKernelSum)*weights.fc1_w(15:22,:)];

numRegsPerFilter = ceil(kernel_size/4);
numBytesValid = numRegsPerFilter*4;

dFeatures = [];
for i = 1:num_filters
    filterVals = [int8(featuresKernelScaled(i,:)),zeros(1,numBytesValid-kernel_size)];
    for j = 1:numRegsPerFilter
        regValue = (filterVals(j*4-3:j*4));
        % Config regs.JFIL.dFeatures_000_to_055
        dFeatures = [dFeatures;typecast(regValue,'uint32')];
    end
end
regs.JFIL.dFeatures = dFeatures;
regs.JFIL.dFeaturesConfThr = uint8(0); % Confidence above this threshold are valid. Relevant for sort features and the convolutions.
regs.JFIL.dFeaturesNorm = uint8(255); % 0 - Do not normalize the sum of the kernels to one

% regs.JFIL.dnnMinConf = ? % used for saving pixels after the NN when the confidence is 0 but the depth is above 0.

%% Configuration for dnn: network and activations weights
regs.JFIL.dnnBypass = false; % To activate the dNN
% 1st layer: [22 -> 10] -> 22*10+10 = 230 regs.
% 2nd layer: [10 ->  5] -> 10*5+5 = 55 regs.
% 3rd layer: [5 -> 4] -> 5*4+4 = 24 regs.
% 4th layer: [4 -> 1] -> 4*1+1 = 5 regs.
% Resulting in a total of 230+55+24+5 = 314 regs.
% Fill the dNN weight regs
ns = [22 10 5 4 1];
s = prod([ns(1:end-1);ns(2:end)]);
dnn_regs = [];
% Add weights
dnn_regs = [dnn_regs; reshape(fc1_w_scaled,s(1),1)];
dnn_regs = [dnn_regs; reshape(weights.fc2_w,s(2),1)];
dnn_regs = [dnn_regs; reshape(weights.fc3_w,s(3),1)];
dnn_regs = [dnn_regs; 8*reshape(weights.fc4_w,s(4),1)]; % Remove the 8 is the net wastrained on the right scale
% Add biases
dnn_regs = [dnn_regs; vec(weights.fc1_biases)];
dnn_regs = [dnn_regs; vec(weights.fc2_biases)];
dnn_regs = [dnn_regs; vec(weights.fc3_biases)];
dnn_regs = [dnn_regs; 8*vec(weights.fc4_biases)];% Remove the 8 is the net wastrained on the right scale

dnn_regs = Utils.fp20('from',dnn_regs);
regs.JFIL.dnnWeights = dnn_regs;
% for i = 1:s(1)
%     regNum = i - 1;
%     regs.JFIL.(strcat('dnnWeights_',sprintf('%03d',regNum))) = dnn_regs(i);
% end

% regs.JFIL.dnnActFunc Leaving it as default (a simple relu)
% JFILnnNorm                   , single , 1        , h3783126F                                                          ,                                                                                                                                                                    
% JFILnnNormInv                , single , 1        , h477A0000                                                            ,                                                                                                                                                                    
regsPlusDNN = regs;    
end
function A_flipped = flip_dims_1_2(A)
    A_flipped = flip(flip(A,1),2);
end