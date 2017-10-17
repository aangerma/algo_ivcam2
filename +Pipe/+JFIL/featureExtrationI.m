function [featuresMat, features] = featureExtrationI(jStream,  regs, luts, instance,lgr,traceOutDir)




lgr.print2file('\t\t------- featureExtrationI -------\n');



%% bypass
if(regs.JFIL.innBypass == 1)
    featuresMat=uint32(zeros(regs.GNRL.imgVsize,regs.GNRL.imgHsize,14));
else
    
    
    %% in->out
    features.conf = single(jStream.conf);
    features.ir = single(jStream.ir);
    features.depth = single(jStream.depth);
    
    
    %% inputs
    inLut = uint32(regs.JFIL.iFeatures);
    input = jStream.ir;
    S = size(input);
    
    
    
    
    %% sort
    sortWsize = [3 3];
    sortWind = Utils.indx2col(S,sortWsize);
    features.sortIr = single(sort(input(sortWind),1));
    features.sortIr = reshape(permute(features.sortIr,[2 1]),S(1),S(2),[]);
  
    %% conv filters
    convWsize = [5 5];
    winInd = Utils.indx2col(S,convWsize);
    inptBlock = jStream.ir(winInd);
      nRegistersPerFilter = ceil(prod(convWsize)/4);
        for i=1:2
        
        lutFilterIndex = (1:nRegistersPerFilter)+(i-1)*nRegistersPerFilter;
        filt = typecast(inLut(lutFilterIndex),'int8');
        filt = vec(filt(1:prod(convWsize)));
        
        
        %convolution only with valid weights
        
        
        %16b x 8b x 6b(25pixels) = 23b (sum of filt weight ==128)
        pixConv = (sum(    bsxfun(@times,int32(inptBlock),int32(filt))   ,1,'native'));
        if(regs.JFIL.iFeaturesNorm(i)) 
            pixConv  = bitshift(pixConv,-7);%if normalizeing - sum is fixed to 128
        end
        
        pixConv=min(single(pixConv),2^16-5);
        pixConv=max(single(pixConv),-(2^16-5));
        
        features.(['filtered' num2str(i)]) = reshape(pixConv,S);
        
    end
    nnNorm = regs.JFIL.nnNorm;

    %% Ttransfprm to resHXresVXfeatures matrix.
    confNorm = single(1/15);
    irNorm = single(1/(2^12-1));
    featuresMat(:,:, 1)=features.depth*nnNorm ;
    featuresMat(:,:, 2)=features.conf*confNorm  ;
    featuresMat(:,:, 3)=features.ir*irNorm    ;
    featuresMat(:,:, 4)=features.sortIr(:,:,1)*irNorm;
    featuresMat(:,:, 5)=features.sortIr(:,:,2)*irNorm;
    featuresMat(:,:, 6)=features.sortIr(:,:,3)*irNorm;
    featuresMat(:,:, 7)=features.sortIr(:,:,4)*irNorm;
    featuresMat(:,:, 8)=features.sortIr(:,:,5)*irNorm;
    featuresMat(:,:, 9)=features.sortIr(:,:,6)*irNorm;
    featuresMat(:,:,10)=features.sortIr(:,:,7)*irNorm;
    featuresMat(:,:,11)=features.sortIr(:,:,8)*irNorm;
    featuresMat(:,:,12)=features.sortIr(:,:,9)*irNorm;
    featuresMat(:,:,13)=features.filtered1*irNorm;
    featuresMat(:,:,14)=features.filtered2*irNorm;
featuresMat = max(0,min(1,featuresMat));

    featuresMat = Utils.fp20('from',featuresMat);
end
if(~isempty(traceOutDir))
    featuresMatTxt = Utils.mat2hex(reshape(permute(featuresMat,[3 1 2]),14,[])',5);
    
    Utils.buildTracer(featuresMatTxt,'JFIL_iFeatures',traceOutDir);
end

lgr.print2file('\t\t----- end featureExtrationI -----\n');

end
