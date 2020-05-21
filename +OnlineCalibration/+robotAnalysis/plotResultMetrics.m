function [] = plotResultMetrics(labels,newLabels,metricData,varargin)
    isSinglepre = ~isempty(contains(varargin,'singlePre'));
    acc = mean(newLabels == labels);
    fig = figure;
    tabplot(1,fig);
    subplot(2,2,[1,2,3,4])
    cm = confusionchart(labels,newLabels);
    xlabel('Valid Optimization');
    ylabel('"GT" comparison');
    title(sprintf('acc = %2.2g',acc))
    
    extraTitles = {'True Negative';'False Positive';'False Negative';'True Positive'};
    for m=1:length(metricData)
        tabplot(m+1,fig);
        
        for k = 1:2
            for j = 1:2
                subplot(2,2,(sub2ind([2, 2], k, j)));
                validPoints = logical((newLabels==k-1) .* (labels==j-1));
                if isSinglepre
                    [hp,vhp] = hist(metricData(m).post(validPoints),10);
                    bar(mean(metricData(m).pre(validPoints)),max(hp),mean(diff(vhp))/10);
                     %vline(mean(metricData(m).pre(validPoints)),'-','Pre');
                else
                    histogram(metricData(m).pre(validPoints),10);
                end
                hold on
                histogram(metricData(m).post(validPoints),10);
                legend({'Pre';'Post'});
                title(sprintf('%s %3.2g%%',extraTitles{sub2ind([2, 2], k, j)},mean(validPoints)*100));
                xlabel(sprintf('%s[%s]',metricData(m).name,metricData(m).units));
                grid on
            end
        end
    end
end

