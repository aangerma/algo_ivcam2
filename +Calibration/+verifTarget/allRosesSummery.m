function seenStepSz = allRosesSummery(I,projStruct,reportF)
% output rose metrics from a given image of a rose piducial
% each angle correspondes to THE DIRECTION OF THE STEP- e.g. the left most
% part of the rose will be with step dir up so it will be in 90 degrees.

poseNames = {'up', 'right','down','left','center'};

if(0)
    %% get roses projected places...
    f = figure(2511234);clf;maximize;
    imagesc(projStruct.Iproj);axis image;colormap gray;
    
    edgeSz = 510;
    
    for gg = 1:5
        title(['choose center point of rose in position: ' poseNames{gg}])
        [x,y] = ginput(1);x = round(x);y = round(y);
        disp(['[' num2str([x-edgeSz/2 y-edgeSz/2 edgeSz edgeSz]) '];'])
    end
    delete(f)
end

RoseProjPoses ={... %[xmin ymin width height] relative to new (0,0)
    [333   10  510  510];
    [1281   257   510   510];
    [1035   790   510   510];
    [89  541  510  510];
    [684  401  510  510];
    };



%% for each rose
seenStepSz = cell(length(RoseProjPoses),1);
% roseM = cell(length(RoseProjPoses),1);
% IroseProj = cell(length(RoseProjPoses),1);
for j=1:length(RoseProjPoses)
    IroseProj = projStruct.Iproj( (RoseProjPoses{j}(2):RoseProjPoses{j}(2)+RoseProjPoses{j}(4)),(RoseProjPoses{j}(1):RoseProjPoses{j}(1)+RoseProjPoses{j}(3)));
     x0 = RoseProjPoses{j}(1:2)+projStruct.x0;
 unprojStruct.x0 = x0;
  unprojStruct.I = I;
    [seenStepSz{j}, angleVec,roseM] = Calibration.verifTarget.stepSizeMetric(IroseProj,unprojStruct,projStruct);
    
end

if(~isempty(reportF))
    figure(reportF);tabplot();
    
    correspondingSubplotInd = [2 6 8 4 5];
    for i=1:length(poseNames)
        if(~isempty(seenStepSz{i}))
            subplot(3,3,correspondingSubplotInd(i));
            polarplot(seenStepSz{i});
            title(['pos: ' poseNames{i} '; mean: ' num2str(mean(seenStepSz{i})) '; std: ' num2str(std(seenStepSz{i}))]);
            
            %             subplot(3,6,correspondingSubplotInd(i)-1);
            %             [x,y] = meshgrid(linspace(0,maxStepSz,nCols),linspace(0,360,size(roseM{i},1)));
            %             imagesc(x(:),y(:),roseM{i});colormap gray;hold on;
            %             plot(seenStepSz{i},y(:,1),'*-')
            %             imagesc(IroseProj{i});axis image;colormap gray;
        end
    end
    %     subplotTitle('rose matrics: each angle correspondes to THE DIRECTION OF THE STEP- e.g. the left most part of the rose will be with step dir up so it will be in 90 degrees')
end


end
