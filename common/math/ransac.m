function [bestInliers,bestModel] = ransac(X,generateModel,generateERR,varargin)
%{
general ransac iteration function
-usage:
    ransac(X,generateModel,generateERR,[name1],[value1],...)
    X - Nxdim input data. N  is the number of data points, dim is the data dimintion
    generateModel - function handle, recieve matrix of size nModelPoints x dim. sould return arbirtary model object
    generateERR -  function handle, recieves arbirtary model object, and Mxdim data points, should return Mx1 error vector
    optional(name value pair):
     -iterations: number of RANSCAN iterations
     -errorThr: threshold value for inlier/outlier separation
     -nModelPoints: number of data point needed to build model
    -seed:  random seed
    
%}

%%%%%%%%%%%%%%%%%%%
%varargin parser:
%%%%%%%%%%%%%%%%%%%
default_iterations = 500;
default_errorThr = 0.01;

inp = inputParser;

inp.addRequired('X',@ismatrix);
inp.addRequired('generateModel',@(x) isa(x,'function_handle') );
inp.addRequired('generateERR',@(x) isa(x,'function_handle') );
inp.addOptional('iterations', default_iterations, @(x)x > 0 && x < 10^5);
inp.addOptional('errorThr', default_errorThr, @(x)x > 0 && x < 10^5);
inp.addOptional('nModelPoints',size(X,2),@(x) isnumeric(x));
inp.addOptional('seed',0,@(x) isnumeric(x));
inp.addOptional('plot',false,@(x)islogical(x) );

parse(inp,X,generateModel,generateERR,varargin{:});
arg = inp.Results;


%%%%%%%%%%%%%%%%%%%
%ransac:
%%%%%%%%%%%%%%%%%%%

nSamples = size(arg.X,1);
dim = size(arg.X,2);
rng(arg.seed);

%find best model by randomly select k samples (k is the dim of the fit) and
%check if it's a good fit
bestInliers=[];
for i = 1:arg.iterations
    %random samples for model generating
    rand_samples = randperm( nSamples, dim );
    X_k = arg.X( rand_samples,: );
    
    %generate the model and find his error compered to the samples set
    tmpModel = arg.generateModel(X_k);
    tmpError = arg.generateERR(tmpModel,arg.X);
    tmpInliers = find(abs(tmpError)<arg.errorThr);
    
    %if we have found a good model- save it
    if( length(tmpInliers) > length(bestInliers) )
        bestInliers = tmpInliers;
        bestModel = tmpModel;
        bestError = sqrt(sum(tmpError.^2)); %R^2 of error
    end

end

if(arg.plot)
    switch(dim)
        case 1
              plotModel = @(x,th,bi) plot(1:nSample,x(:,1),'.',bi,x(bi,2),'r.');
        case 2
            plotModel = @(x,th,bi) plot(x(:,1),x(:,2),'.',x(bi,1),x(bi,2),'.r');
   
        otherwise
            plotModel = @(x,th,bi) plot3(x(:,1),x(:,2),x(:,3),'b.',x(bi,1),x(bi,2),x(bi,3),'ro');
   
    end
    plotModel(arg.X, bestModel,bestInliers);
    title(sprintf('R^2 of Error: %f',bestError));
end

end