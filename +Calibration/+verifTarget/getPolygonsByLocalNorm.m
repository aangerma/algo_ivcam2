function polygons = getPolygonsByLocalNorm(I,NormalizationRoiSizeFactor)
if(nargin == 1)
    NormalizationRoiSizeFactor = 40; %bigger number -> smaller roi
end

%% normalize the image
roiAreaSz = round(min(size(I))/NormalizationRoiSizeFactor);

Imn = imerode(I,ones(roiAreaSz)); %find lowest value for each fixel in N size area
Imx = imdilate(I,ones(roiAreaSz));%find highest value for each fixel in N size area

In = (I-Imn)./(Imx-Imn);
In(isnan(In))=0;
if(0)
    %%
    figure(5721);imagesc(In);axis image
    drawnow;
    colormap gray
end

Inorm = single(In);
%% threshold the image and find all closed polygons that form
[polygons,polylines] = imVectorize(Inorm,0.5);%double(mean(Inorm(:))));

if(0)
    %%
    figure(5721);clf;imagesc(In);axis image
    drawnow;
    colormap gray; hold on;
     maxInd = maxind(cellfun(@(x) size(x,1),polygons));
    plot(polygons{maxInd}(:,1),polygons{maxInd}(:,2),'*');
end

end

