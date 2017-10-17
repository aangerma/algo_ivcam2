function [seenStepSz, angleVec,roseMo] = stepSizeMetric(I,unprojStruct,projStruct)
% getsa cropped image of a rose and outputs a seen step size vector with
% it's corresponding angles

numBlackWedges = 36;

if(nargin==1)
    isWithUnproj = 0;
else
    isWithUnproj = 1;
end




%% find the rose on projected image

NormalizationRoiSizeFactor = 10;

%let's make it more robust by tring different NormalizationRoiSizeFactor
dn = floor(NormalizationRoiSizeFactor/5);
NormalizationRoiSizeFactorOptions = [NormalizationRoiSizeFactor 3*dn:dn:7*dn];
NormalizationRoiSizeFactorOptions(end-2) = [];

rosePoly = [];
for k = NormalizationRoiSizeFactorOptions
    [ polygons, area, circumference ] = Calibration.verifTarget.findCircles(I,k);
    [~,sortInd] = sort(area);
    sortedPoly = polygons(sortInd);
    
    %check if we actually detected the rose by area
    if(numel(I)/max(area) <=10)
        rosePoly = sortedPoly{end};
        break;
    else
        continue;
    end
    
end


%% find ellipse coeffs of projected image
if(~isempty(rosePoly))
    X = rosePoly(:,1);
    Y = rosePoly(:,2);
    report = Calibration.verifTarget.ellipsefit(X,Y);
    
    
    
    %% get rose angle-radius matrix on unprojected image
    % rose has X black strips & X white strips - so lets take radius
    % samples in correspondence
    
    numSamplesInStrip = 20;
    nSamples = numBlackWedges*2*numSamplesInStrip;
    samples = 1:nSamples;
    samples = samples/nSamples;
    
    
    x = cos(2*pi*samples);
    y = -sin(2*pi*samples);
    
    [U,S,V] = svd(report.Q);
    Snew = [1/sqrt(S(1,1)) 0; 0 1/sqrt(S(2,2))];
    xyEllipse = U*Snew*V'*[x;y];
    
    meanRinPixels = mean(sqrt(xyEllipse(1,:).^2+xyEllipse(2,:).^2));
    maxStepSz = meanRinPixels*2*pi/(numBlackWedges*2);
    
    if(0)
        %%
        figure(23512);clf;
        imagesc(I);colormap gray;axis image;hold on
        plot(X,Y,'*b');
        plot(xyEllipse(1,:)+report.d(1),xyEllipse(2,:)+report.d(2),'*r');
    end
    
    nCols = 100;
    roseMo = zeros(size(xyEllipse,2),nCols);
    
    for i=1:nCols
        r = i/nCols;
        if(isWithUnproj) %the unproj is importent so that the pixel size will be accurate- on projected image it's all different
            
            roseMxy = projStruct.Hproj\[r*xyEllipse(1,:)+report.d(1)+unprojStruct.x0(1); r*xyEllipse(2,:)+report.d(2)+unprojStruct.x0(2)  ;ones(size(xyEllipse(1,:)))];
            [yg,xg]=ndgrid(1:size(unprojStruct.I,1),1:size(unprojStruct.I,2));
            roseMo(:,i) =interp2(xg,yg,unprojStruct.I,roseMxy(1,:),roseMxy(2,:));
        else
            roseMxy = [r*xyEllipse(1,:)+report.d(1); r*xyEllipse(2,:)+report.d(2)];
            [yg,xg]=ndgrid(1:size(I,1),1:size(I,2));
            roseMo(:,i) =interp2(xg,yg,I,roseMxy(1,:),roseMxy(2,:));
        end
        
        
        
    end
    
    if(0)
        %%
        figure;imagesc(roseM);colormap gray;axis image;
    end
    
    
    
    roseM = roseMo;
    %%% ==== all convolution step size finding... ===
    %         %% cals on matrix
    %         numCycles = 4;
    %         tamplate = repmat([1 -1],1,numCycles);
    %         tamplate = vec(repmat(tamplate,numSamplesInStrip,1));
    %
    %         %norm
    %         leftImPrecentage = 0.7; %exclude the black strip.
    %
    %         maxRoseM = max(vec(roseM(:,1:floor(leftImPrecentage*nCols))));
    %         minRoseM = min(vec(roseM(:,1:floor(leftImPrecentage*nCols))));
    %
    %         roseM = 2*(roseM-minRoseM)/(maxRoseM-minRoseM);
    %         roseM = roseM - mean(vec(roseM(:,1:floor(leftImPrecentage*nCols))));
    %
    %         %do circular conv
    %         roseMCirc =  [roseM;roseM;roseM] - mean(vec(roseM(:,1:floor(0.7*nCols))));
    %         roseMConv = conv2(roseMCirc,tamplate,'same');
    %
    %         % get best hits and plot curve. remove outliers
    %         ABS_RELATIVE_COLOR_TH = 0.2;%range [0:1]
    %         convGrayScoreTH = ABS_RELATIVE_COLOR_TH*length(tamplate);
    %
    %         roseMconvTh = roseMConv;
    %         roseMconvTh( roseMconvTh<convGrayScoreTH) = 0;
    %         roseMconvTh( roseMconvTh>0) = 1;
    %
    %
    %         roseMDilate = imdilate(roseMconvTh,strel('rectangle',[2*numSamplesInStrip,3]));
    %         roseMDilate(roseMDilate(:)>0) = 1;
    %
    %         roseMDilate = roseMDilate(1+size(roseM,1):size(roseM,1)*2,:);%take the middle one
    %
    %
    %
    %         curv = cellfun(@(x) iff(isempty(find(x,1)),nCols,find(x,1)) ,      mat2cell(roseMDilate,ones(size(roseMDilate,1),1),size(roseMDilate,2)) );
    %         seenStepSz = curv/nCols*maxStepSz;
    %         %         seenStepSz = circshift(seenStepSz,ceil(length(seenStepSz)/4));
    %                     [x,y] = meshgrid(linspace(0,maxStepSz,nCols),linspace(0,360,size(roseM,1)));
    %
    %         angleVec = y(:,1);
    
    
    %% find step size by deviation from noise
    roseMn = normByMax(roseM);
    varIm=reshape(var(roseMn(Utils.indx2col(size(roseMn),[41 3]))),size(roseMn));
    varNoise = mean(vec(varIm(:,1:10)));
    varMap = sqrt(varIm)>3*sqrt(varNoise);
    varMapX3 = [varMap;varMap;varMap];
    
    %% remove small noise
    CC = bwconncomp(varMapX3);
    numPixels = cellfun(@numel,CC.PixelIdxList);
    [biggest,idx] = max(numPixels);
    smallCC = 1:CC.NumObjects;
    smallCC(idx) = [];
    
    for ii=smallCC
        varMapX3(CC.PixelIdxList{ii}) = 0;
    end
    
    %% find curve, smooth and cut to the middle part
    curv = cellfun(@(x) iff(isempty(find(x,1)),nCols,find(x,1)) ,      mat2cell(varMapX3,ones(size(varMapX3,1),1),size(varMapX3,2)) );
    
    seenStepSz = curv/nCols*maxStepSz;
    avKernelSzInDeg = 20;
    avSz = size(roseM,1)/360*avKernelSzInDeg; 
    seenStepSz = conv(seenStepSz,ones(1,avSz)/avSz,'same');
    seenStepSz = seenStepSz(size(varMap,1)+1:size(varMap,1)*2);
    
    seenStepSz = (seenStepSz + circshift(seenStepSz,ceil(length(seenStepSz)/2)))/2; %av in 180 phase to see the symmetry line
    
    %% phase shift
    phase90 = ceil(length(seenStepSz)/4);
    seenStepSz = circshift(seenStepSz,phase90); %the step direction is orthogonal to the step
    
    [x,y] = meshgrid(linspace(0,maxStepSz,nCols),linspace(0,360,size(roseM,1)));
    angleVec = y(:,1);
    
    if(1)
        %%
        figure(12312);tabplot();
        
        seenStepSz4Disp = circshift(seenStepSz,-phase90);
        
        a(1) = subplot(121);
        imagesc(x(:),y(:),roseM);colormap gray;hold on;
        plot(seenStepSz4Disp,angleVec,'*-')
        title(['mean: ' num2str(mean(seenStepSz4Disp)) '; std: ' num2str(std(seenStepSz4Disp))])
        ylabel('seen step angle [deg]');
        xlabel('seen step size [pixel]');
        
        a(2) = subplot(122);imagesc(x(:),y(:),varMapX3(size(varMap,1)+1:size(varMap,1)*2,:));colormap gray;
        ylabel('seen step angle [deg]');
        xlabel('seen step size [pixel]');
        
        %             a(3) = subplot(133);imagesc(x(:),y(:),roseMDilate);colormap gray;
        %             ylabel('angle [deg]');
        %             xlabel('seen step size [pixel]');
        
        linkaxes(a)
    end
    
end



end