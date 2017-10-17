function featuresMat = featureExtrationD(jStream,  regs, luts, instance, lgr,traceOutDir)

lgr.print2file('\t\t------- featureExtrationD -------\n');





%% bypass
if(regs.JFIL.dnnBypass == 1)
    featuresMat=zeros(regs.GNRL.imgVsize,regs.GNRL.imgHsize,22,'uint32');
else



%% in->out (through)
% features.bilt3 = Utils.fp20(single(jStream.features.bilt3)); bl3 is the depth...



%% jStream.depths
inLut = uint32(regs.JFIL.dFeatures);

S = size(jStream.depth);
confThr = regs.JFIL.dFeaturesConfThr;
highConfMask = (jStream.conf > confThr);
sortType = regs.JFIL.dFeaturesSortType;


%% sort
%sort modes:
% 0 - low conf are 0 and place at the beginning
% 1 - low conf are fp18= 0x0 and place at the beginning
% 2 - low conf are fp18 and place at both ends equally (start from left==beginning)
% 3 - valid min and max are strech to fill the ends. if all low conf put all fp16(nan)

sortWsize = [3 3];
sortWind = Utils.indx2col(S,sortWsize);
if(sortType == 0)
    sortD = sort(  double(jStream.depth(sortWind)).*highConfMask(sortWind)  , 1  );
elseif (sortType == 1)
    error('Not supported: cannnot input NaN to NN (29/3/2017 OM)');
    sortD = sort(  double(jStream.depth(sortWind)).*highConfMask(sortWind)  , 1  );
    sortD(sortD==0) = nan;
elseif (sortType == 2)
    sortD = sort(  double(jStream.depth(sortWind)).*highConfMask(sortWind)  , 1  );
    even_mask = zeros(size(sortD));
    even_mask(2:2:end,:) = 1;
    sorted_low_conf_mask = zeros(size(sortD));
    sorted_low_conf_mask(sortD==0) = 1;
    even_low_conf_mask = (even_mask & sorted_low_conf_mask);
    sortD(even_low_conf_mask) = inf;
    sortD = sort(sortD,1);
    sortD(sortD==inf) = 0;     
elseif (sortType == 3)
    sortD = sort(  double(jStream.depth(sortWind)).*highConfMask(sortWind)  , 1  );
    sorted = sortD;
    sorted(sortD==0) = nan;
   
    
    even_mask = zeros(size(sortD));
    even_mask(2:2:end,:) = 1;
    sorted_low_conf_mask = zeros(size(sortD));
    sorted_low_conf_mask(sortD==0) = 1;
    even_low_conf_mask = (even_mask & sorted_low_conf_mask);
    sortD(even_low_conf_mask) = inf;
    sortD = sort(sortD,1);
    
    mn = repmat(min(sorted,[],1),size(sortD,1),1);
    mx = repmat(max(sorted,[],1),size(sortD,1),1);
    lower_mask = false(size(sortD));
    lower_mask(sortD==0) = 1;
    lower = lower_mask.*mn;
    upper_mask = false(size(sortD));
    upper_mask(sortD==inf) = 1;
    upper = upper_mask.*mx;
    sortD(lower_mask) = lower(lower_mask);
    sortD(upper_mask) = upper(upper_mask);
    % this should only happen if all the values in the 3x3 patch were NaN
    sortD(isnan(sortD))=0;
    
end
features.sortD = single(sortD);
features.sortD = reshape(permute(features.sortD,[2 1]),S(1),S(2),[]);



%% conv
convWsize = [5 5];
nRegistersPerFilter = ceil(prod(convWsize)/4);
winInd = Utils.indx2col(S,convWsize);

confBlock = jStream.conf(winInd);
cbinBlock = int32(confBlock>confThr);
dpthBlock = jStream.depth(winInd);
features.filtered=cell(8,1);
for i=1:8%length(inLut)/ceil(prod(convWsize)/2);
%%
    if(i==1)
        inptBlock = uint16(confBlock);
    else
        inptBlock = dpthBlock;
    end
    lutFilterIndex = (1:nRegistersPerFilter)+(i-1)*nRegistersPerFilter;
    filt = typecast(inLut(lutFilterIndex),'int8');
    filt = vec(filt(1:prod(convWsize)));
    
    
    %convolution only with valid weights
    filtMasked = bsxfun(@times,int32(filt),cbinBlock);
    
    %16b x 8b x 6b(25pixels) = 23b (sum of filt weight ==128)
    pixConv = (sum(    int32(inptBlock).*int32(filtMasked)    ,1,'native'));
	if(regs.JFIL.dFeaturesNorm(i))
		filtMaskedSum = single(sum(filtMasked)); %max sum is 128
		zerosum = (filtMaskedSum==0);
        if(regs.MTLB.fastApprox(4))
            pixConvDenom = 1./filtMaskedSum;
        else
            pixConvDenom = Utils.fp32('inv',filtMaskedSum);
            
        end
		pixConv = single(pixConv).*pixConvDenom;
		pixConv(zerosum) = 0;
	end
	
	pixConv=min(single(pixConv),2^16-5);
	pixConv=max(single(pixConv),-(2^16-5));
    
    features.filtered{i} = reshape(pixConv,S);
    
    if(0)
%%
        num_f = 234556;
        figure(num_f+i);clf;
        types = {'mean 3*3' ,'gauss 3*3', 'laplace 3*3' , 'gauss 5*5','mean 5*5','log 5*5','divy','divx'}; %There are exactly 8 convolution filters, 7 for depth and 1 for conf.
    inputImg = reshape(inptBlock(13,:),size(jStream.depth));
        subplot(121);
        imagesc(inputImg);
        title('before');
        subplot(122);
        after = Utils.fp20('to',features.(['filtered' num2str(i)]));
        imagesc(after);
        title('after');
        subplotTitle(['featureExtrationD:' types{i}]);
        mx = max([inputImg(:);after(:)]);
        mn = min([inputImg(:);after(:)]);
        subplot(121); caxis([mn mx]);
        subplot(122); caxis([mn mx]);
disp(reshape(filt,convWsize))
    end
end

%% Ttransfprm to resHXresVXfeatures matrix.
    confNorm = single(1/15);
    irNorm = single(1/(2^12-1));

nnNorm = regs.JFIL.nnNorm;
featuresMat(:,:, 1)=single(jStream.depth)*nnNorm ;   
featuresMat(:,:, 2)=single(jStream.conf)*confNorm  ;   
featuresMat(:,:, 3)=single(jStream.ir)*irNorm    ;   
featuresMat(:,:, 4)=single(jStream.features.featA)*nnNorm ;   
featuresMat(:,:, 5)=single(jStream.features.featB)*nnNorm ;   
featuresMat(:,:, 6)=features.sortD(:,:,1)*nnNorm;   
featuresMat(:,:, 7)=features.sortD(:,:,2)*nnNorm;   
featuresMat(:,:, 8)=features.sortD(:,:,3)*nnNorm;   
featuresMat(:,:, 9)=features.sortD(:,:,4)*nnNorm;   
featuresMat(:,:,10)=features.sortD(:,:,5)*nnNorm;   
featuresMat(:,:,11)=features.sortD(:,:,6)*nnNorm;   
featuresMat(:,:,12)=features.sortD(:,:,7)*nnNorm;   
featuresMat(:,:,13)=features.sortD(:,:,8)*nnNorm;   
featuresMat(:,:,14)=features.sortD(:,:,9)*nnNorm;   
featuresMat(:,:,15)=features.filtered{1}*confNorm;
featuresMat(:,:,16)=features.filtered{2}*nnNorm;
featuresMat(:,:,17)=features.filtered{3}*nnNorm;
featuresMat(:,:,18)=features.filtered{4}*nnNorm;
featuresMat(:,:,19)=features.filtered{5}*nnNorm;
featuresMat(:,:,20)=features.filtered{6}*nnNorm;
featuresMat(:,:,21)=features.filtered{7}*nnNorm;
featuresMat(:,:,22)=features.filtered{8}*nnNorm;
featuresMat = max(0,min(1,featuresMat));

featuresMat = Utils.fp20('from',featuresMat);
end
if(~isempty(traceOutDir))
    featuresMatTxt = Utils.mat2hex(reshape(permute(featuresMat,[3 1 2]),22,[])',5);
        Utils.buildTracer(featuresMatTxt,'JFIL_dFeatures',traceOutDir);
end

lgr.print2file('\t\t----- end featureExtrationD -----\n');

