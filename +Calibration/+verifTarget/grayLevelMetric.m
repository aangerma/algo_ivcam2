function [Ires, Zres] = grayLevelMetric( I,Z,projStruct,reportF )
%mean & std of each color.
%assumes the blackest is at the top left corner.
try

poseNames = {'upper left', 'upper right','lower right','lower left'};

if(0)
    %% get 3x3 cubes places...
    f = figure(2519134);clf;maximize;
    imagesc(projStruct.Iproj);axis image;colormap gray;
    
    edgeSz = 300;
    
    for gg = 1:4
        title(['choose center point of gray level 3X3 cubes in ' poseNames{gg}])
        [x,y] = ginput(1);x = round(x);y = round(y);
        disp(['[' num2str([x-edgeSz/2 y-edgeSz/2 edgeSz edgeSz]) '];'])
    end
delete(f);
 
end



poses ={... %[xmin ymin width height] relative to new (0,0)
[158  251  300  300];
[1246    77   300   300];
[1423   754   300   300];
[334  932  300  300];
    };

Ires = cell(length(poses),1);
imageType{1} = I;

Zres = [];
if(~isempty(Z))
    Zres = cell(length(poses),1);
    imageType{2} = Z;
end

IgrayLevel = cell(length(poses),1);
rects = cell(length(poses),1);



%constants
DIFF_BETWEEN_CENTER_OF_CUBES = 80; %estimated difference between centers of adjecent cubes relative to projected image;
KERNEL_SZ = 71;
MARGIN_WIDTH = 40;

KERNEL_SZ = KERNEL_SZ+mod(KERNEL_SZ+1,2); %make it always odd
MARGIN_WIDTH = MARGIN_WIDTH +mod(MARGIN_WIDTH,2);%make it always even





%% run on each 3X3
for j=1:length(poses)
    
    IgrayLevel{j} = projStruct.Iproj( (poses{j}(2):poses{j}(2)+poses{j}(4)),(poses{j}(1):poses{j}(1)+poses{j}(3)));
    if(~isempty(Z))
        ZgrayLevel{j} = projStruct.Iproj( (poses{j}(2):poses{j}(2)+poses{j}(4)),(poses{j}(1):poses{j}(1)+poses{j}(3)));
    end
    
    x0 = poses{j}(1:2)+projStruct.x0;
    
    
    
    
    
    centerInd = cell(2,1);
    actualDiffBetweenCenterOfCubes = cell(2,1);
    
    %% find centers of cubes in X & Y directions
    for k=1:2
        if(k==2)
            IgrayLevel{j} = IgrayLevel{j}';
        end
        
        convI = conv2(IgrayLevel{j},ones(KERNEL_SZ),'valid');
        blackInd = minind(convI(:));
        [minRow,minCol] = ind2sub(size(convI),  blackInd  );
        minRow = minRow+(KERNEL_SZ-1)/2; minCol = minCol+(KERNEL_SZ-1)/2;
        
        if(minCol>size(IgrayLevel{j},2)/2)
            IgrayLevel{j} = fliplr(IgrayLevel{j});
            convI = conv2(IgrayLevel{j},ones(KERNEL_SZ),'valid');
            blackInd = minind(convI(:));
            [minRow,minCol] = ind2sub(size(convI),  blackInd  );
            minRow = minRow+(KERNEL_SZ-1)/2; minCol = minCol+(KERNEL_SZ-1)/2;
            
        end
        
        meanRow = mean(  IgrayLevel{j}(minRow-(KERNEL_SZ-1)/2:minRow+(KERNEL_SZ-1)/2,:)  ,1);
        
        %% determine center index
        % find several following peaks of mean row
        peaks = zeros(1,2);
        for i=1:length(peaks)
            peaks(i) = maxind(meanRow(minCol+(i-1)*DIFF_BETWEEN_CENTER_OF_CUBES:minCol+i*DIFF_BETWEEN_CENTER_OF_CUBES-1))+minCol-1+(i-1)*DIFF_BETWEEN_CENTER_OF_CUBES;
        end
        %extrapolate the other unseen peaks
        actualDiffBetweenCenterOfCubes{k} = mean(diff(peaks)); %we have a difference between this and CENTER_CUBES_DIFF because of not perfect projection
        
        allPeaks = round([peaks(1)-actualDiffBetweenCenterOfCubes{k} peaks peaks(end)+actualDiffBetweenCenterOfCubes{k}-1 ]);
        centerInd{k} = round(mean([vec(allPeaks(1:end-1))  vec(allPeaks(2:end))],2));
        
        
    end
    
    %% unproject the cubes to the original image
    IgrayLevel{j} = IgrayLevel{j}';
    
    centersXY = zeros(9,2);
    centersXY(:,1) = vec(repmat(vec(centerInd{1})',3,1));
    centersXY(:,2) = vec(repmat(vec(centerInd{2}),3,1));
    
    rects{j} = zeros(9,4);
    rects{j}(:,1) = round(centersXY(:,1)-actualDiffBetweenCenterOfCubes{1}/2+MARGIN_WIDTH/2);
    rects{j}(:,2) = round(centersXY(:,2)-actualDiffBetweenCenterOfCubes{2}/2+MARGIN_WIDTH/2);
    rects{j}(:,3) = actualDiffBetweenCenterOfCubes{1}-MARGIN_WIDTH;
    rects{j}(:,4) = actualDiffBetweenCenterOfCubes{2}-MARGIN_WIDTH;
    
    Ires{j} = cell(3,3);
    if(~isempty(Z))
        Zres{j} = cell(3,3);
    end
    
    %% find the mean & std for each
    for m=1:9
        
        rectCornersProj = [...
            rects{j}(m,1) rects{j}(m,1)+rects{j}(m,3)    rects{j}(m,1)+rects{j}(m,3)   rects{j}(m,1);
            rects{j}(m,2) rects{j}(m,2)               rects{j}(m,2)+rects{j}(m,4)   rects{j}(m,2)+rects{j}(m,4);
            ones(1,4)];
        rectCornersProj = rectCornersProj+[x0(1); x0(2);0];
        
        rectCorners = projStruct.Hproj\rectCornersProj;
        rectCorners = rectCorners./rectCorners(3,:);
        
        mask = poly2mask(rectCorners(1,:),rectCorners(2,:),size(I,1),size(I,2));
        
        %get results
        for t=1:length(imageType)
            rawData = imageType{t}(mask(:));
%             cubeMean = mean(rawData);
%             cubeStd = std(rawData);
            if(t==1)
                Ires{j}{m} = rawData;
            else
                Zres{j}{m} = rawData;
            end
        end
    end
    
    
    
end


if(~isempty(reportF))
    %%
    figure(reportF);
    for i=1:length(imageType)
        tabplot();
        projImages = IgrayLevel;
        res = Ires;
        if(i==2)
            projImages = ZgrayLevel;
            res = Zres;
        end
        
        for j=1:length(poses)
            subplot(2,2,j)
            imagesc(projImages{j});colormap gray;axis image;hold on;
            title(poseNames{j});
            for m=1:9
                rectangle('Position',rects{j}(m,:),'EdgeColor','b');
                text(rects{j}(m,1)-rects{j}(m,3)/2,rects{j}(m,2)+rects{j}(m,4)/2,sprintf(['mean: ' num2str(mean(res{j}{m})) '\nstd: ' num2str(std(res{j}{m}))]),'color','g')
            end
            
        end
    end
    
    drawnow;
end

catch e 
    ee.message = sprintf(['ARE YOU SURE THAT THE TARGET IS IN THE RIGHT DIRECTION??? THE BLACKEST SQUARE SHOULD BE TOP LEFT!! \nactual error: ' e.message]);
    ee.stack = e.stack;
    ee.identifier = e.identifier;
    error(ee);
end


end

