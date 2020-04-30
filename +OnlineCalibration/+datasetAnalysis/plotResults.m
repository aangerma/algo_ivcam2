function [] = plotResults(labels,newLabels,uvPre,uvPost,gidPre,gidPost,analysisParams)
    acc = mean(newLabels == labels);

    figure,
    subplot(2,6,[1,2,7,8])
    cm = confusionchart(labels,newLabels);
    xlabel('Valid Optimization');
    ylabel('"Good" UV Err');
    title(sprintf('acc = %2.2g',acc))
    extraTitles = {'True Negative';'False Positive';'False Negative';'True Positive'};
    pVec = [3,4,9,10];
    pVecGid = [5,6,11,12];
    for k = 1:2
        for j = 1:2
            subplot(2,6,pVec(sub2ind([2, 2], k, j)));
            validPoints = logical((newLabels==k-1) .* (labels==j-1));
            plot(analysisParams.successFunc(:,1),analysisParams.successFunc(:,2),'linewidth',2);
            hold on 
            plot(uvPre(validPoints),uvPost(validPoints),'*');
            title(sprintf('%s %3.2g%%',extraTitles{sub2ind([2, 2], k, j)},mean(validPoints)*100));
            xlabel('UV Pre')
            ylabel('UV Post')
            grid on
            legend({'Success Line';'Scene Point'});
            
            
            subplot(2,6,pVecGid(sub2ind([2, 2], k, j)));
            validPoints = logical((newLabels==k-1) .* (labels==j-1));
            histogram(gidPre(validPoints));
            hold on
            histogram(gidPost(validPoints));
            legend({'gidPre';'gidPost'});
            title(sprintf('%s',extraTitles{sub2ind([2, 2], k, j)}));
            xlabel('GID[mm]')
            grid on
        end
    end
    figure,
    extraTitles = {'True Negative';'False Positive';'False Negative';'True Positive'};
    for k = 1:2
        for j = 1:2
            subplot(2,2,(sub2ind([2, 2], k, j)));
            validPoints = logical((newLabels==k-1) .* (labels==j-1));
            histogram(uvPre(validPoints));
            hold on
            histogram(uvPost(validPoints));
            legend({'uvPre';'uvPost'});
            title(sprintf('%s %3.2g%%',extraTitles{sub2ind([2, 2], k, j)},mean(validPoints)*100));
            xlabel('UV[pix]')
            grid on
        end
    end
end

