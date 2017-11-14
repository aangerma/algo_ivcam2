function [depthOut] = dnnExact(dFeatures)
%DNNEXACT loades the dnn weights in single format and pass the features
%through the net. Should replicate the results viewed in tensorflow.


weight_file_path = 'X:\Data\IvCam2\NN\JFIL\NN_Weights\depth_NN_fixed_29_10.mat';
weights = load(weight_file_path);

[height,width,~] = size(dFeatures);
nnNorm = 1/64000;
n_depth_filters = 7;

depthIn = padarray(dFeatures(:,:,1),[2,2],'replicate');
confIn = padarray(dFeatures(:,:,2),[2,2],'replicate');

% Apply the conf convlution feature
confFeature = conv2(confIn,flip_dims_1_2(weights.conf_filter_w),'valid');

depthFeatures = zeros(height,width,7);
for i = 1:n_depth_filters
    depthFeatures(:,:,i) = conv2(depthIn,flip_dims_1_2(weights.depth_filters_w(:,:,i)),'valid');
end


dFeatures = cat(3,dFeatures(:,:,1:14),confFeature,depthFeatures);
dFeatures(dFeatures < 0) = 0;


n_features = 22;
n_pixels = height*width;
dFeatures = reshape(dFeatures,[n_pixels,n_features]);

for i = 1:4
    w = weights.(sprintf('fc%d_w',i));
    if min(size(w)) == 1
        w = w';
    end
    b = weights.(sprintf('fc%d_biases',i));
    dFeatures = bsxfun(@plus,dFeatures*w,b);
    dFeatures(dFeatures < 0) = 0;
end
depthOut = reshape(dFeatures,[height,width]) * 8 /nnNorm;

end

function A_flipped = flip_dims_1_2(A)
    A_flipped = flip(flip(A,1),2);
end
