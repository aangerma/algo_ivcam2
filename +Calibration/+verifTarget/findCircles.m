function [ polygons, area, circumference ] = findCircles(I,NormalizationRoiSizeFactor)
%finds circles in given image

if(nargin == 1)
    NormalizationRoiSizeFactor = 40; %bigger number -> smaller roi
end

polygons = Calibration.verifTarget.getPolygonsByLocalNorm(I,NormalizationRoiSizeFactor);


%% find polygons that are similar to a circle
circlity = zeros(size(polygons));
area = zeros(size(polygons));
circumference = zeros(size(polygons));
for k=1:length(polygons)
    [a,c] =pgonProperties(polygons{k}); %a = area, l = circumference
    area(k) = abs(a);
    circumference(k)= abs(c);
    r1 = circumference(k)/(2*pi); %find circle radius by circumference
    r2 = sqrt(area(k)/pi); %find circle radius by area
    circlity(k) = r1/r2; %if this is a circle- then both r1/2 are close
end

delete =abs(circlity-1)>0.15;
polygons(delete) = [];
area(delete) = [];
circumference(delete) = [];


if(0)
    %%
    figure(2341911);imagesc(I); colormap gray; hold on;
    for i=1:size(polygons,1)
        plot(polygons{i}(:,1),polygons{i}(:,2),'*')
    end
end
%% remove noise polygons- low number of points
th = ceil(min(size(I))/30);
noiseOut = cellfun(@(x) size(x,1)<th, polygons);
polygons(noiseOut) = [];
area(noiseOut) = [];
circumference(noiseOut) = [];
end

