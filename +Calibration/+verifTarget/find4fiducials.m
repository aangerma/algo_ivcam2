function piducialCenter = find4fiducials(I,NormalizationRoiSizeFactor)
% find 4 fiducial places clockwise in a given imag
%
% fiducials: 3 circles:
% inner: black radius;
R1 = 0.6;
% second: white radius;
R2 = 1.2;
% outer: black radius;
R3 = 1.8;

R = [R1 R2 R3];

if(nargin == 1)
    NormalizationRoiSizeFactor = 50; %bigger number -> smaller roi
end

%let's make it more robust by tring different NormalizationRoiSizeFactor
dn = floor(NormalizationRoiSizeFactor/5);
NormalizationRoiSizeFactorOptions = [NormalizationRoiSizeFactor 3*dn:dn:7*dn];
NormalizationRoiSizeFactorOptions(end-2) = [];

for i = NormalizationRoiSizeFactorOptions
    try
        piducialCenter = find4fiducialsAux(I,i,R);
    catch e
        if(strcmp(e.identifier,'find4fiducials:no4fid'))
            if(i==NormalizationRoiSizeFactorOptions(end))
                throw(e);
            end
            
            continue;
        else
            throw(e);
        end
    end
    return; % if no error
end

end




function piducialCenter = find4fiducialsAux(I,NormalizationRoiSizeFactor,R)

try
    I = double(I);
    [ polygons, area, circumference ] = Calibration.verifTarget.findCircles(I,NormalizationRoiSizeFactor);
    
    if(0)
        %%
        figure(2341911);imagesc(I); colormap gray; hold on;
        for i=1:size(polygons,1)
            
            plot(polygons{i}(:,1),polygons{i}(:,2),'*')
        end
    end
    
    
    %% find polygons centers
    realCenters = cell2mat(cellfun(@mean,polygons,'uni',0));
    
    %% find 3NN with min distance between them to determine the fiducial
    [IDX,D] = knnsearch(realCenters,realCenters,'k',3);
    
    D3 = sum(D,2);
    [summedDist,ind] = sort(D3);
    
    %% take all 3 grouped polygons with close centers
    th = min(size(I))/70;
    indClose = ind(summedDist<th);
    
    if(0)
        %%
        figure(234111);imagesc(I); colormap gray; hold on
        for i=1:length(indClose)
            for j=1:3
                poly = polygons{IDX(indClose(i),j)};
                plot(poly(:,1),poly(:,2),'*');
            end
        end
    end
    
    %% threshold by area relations
    piducialInd = unique(sort(IDX(indClose,:),2),'rows');
    
    piducialArea = area(piducialInd);
    areaSorted = sort(piducialArea,2);
%     piducialInd( (areaSorted(:,2)./areaSorted(:,1))/(R(2)^2/R(1)^2) - 0.5 > 1 ,:)=[];
%     piducialInd( (areaSorted(:,3)./areaSorted(:,2))/(R(3)^2/R(2)^2) - 0.5 > 1 ,:)=[];
%     
    piducialInd = piducialInd(1:4,:); %take top 4 (by closest centers)
    
    
    %% find their centers
    
    piducialCenterIndTmp = realCenters(vec(piducialInd.'),:);
    
    piducialCenter = zeros(size(piducialInd,1),2);
    for i=1:size(piducialInd,1)
        piducialCenter(i,:) = mean(piducialCenterIndTmp(3*(i-1)+1:3*(i),:));
    end
    
    if(0)
        %%
        figure(234111);imagesc(I); colormap gray; hold on
        for i=1:size(piducialCenter,1)
            plot(piducialCenter(i,1),piducialCenter(i,2),'*')
        end
    end
    
    
    %% find clockwise places
    blInd = minind(piducialCenter(:,1)+piducialCenter(:,2));
    urInd = maxind(piducialCenter(:,1)+piducialCenter(:,2));
    % find br - x large y small
    [~,i] = sort(piducialCenter(:,2));
    brInd = i(3-1+find(i(3:4)~= urInd));
    
    sortedInd = [blInd 10-brInd-blInd-urInd urInd brInd]; %clockwise starting from bl
    piducialCenter = piducialCenter(sortedInd,:);
    
catch
    error('find4fiducials:no4fid','could not find 4 fiducials! Is all four fiducials are COMPLETELY visible?')
end
end