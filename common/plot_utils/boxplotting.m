function  bp = boxplotting(X,G,Labels,YLabel,numOfSig)
    % bp = boxplot(allHAngle,grouping);
    bp = boxplot(X,G);
    set(bp(7,:),'Visible','off');
    
    ylabel(YLabel);
    means = accumarray(G,X,[length(unique(G)) 1],@nanmean); mmeans = mean(means);
    stds = accumarray(G,X,[length(unique(G)) 1],@nanstd);
    meansStr  =cellfun(@(x) sprintf('\\mu = %s',num2str(x,3)),num2cell(means),'uni',0);
    text(unique(G)-0.125,means+mmeans/5,meansStr,'FontWeight','bold')
    stdStr  = cellfun(@(x) sprintf('%d\\sigma = %s',numOfSig,num2str(x,3)),num2cell(numOfSig*stds),'uni',0);
    text(unique(G)-0.125,means+numOfSig*stds+mmeans/5,stdStr,'FontWeight','bold')
    ylim([min(means-numOfSig*stds)*1.1 max(means+numOfSig*stds)*1.1]);
    
    
    h = flipud(findobj(gca,'Tag','Upper Whisker'));
    for j=1:length(h);
        ydata = get(h(j),'YData');
        ydata(2) = means(j)+numOfSig*stds(j);
        set(h(j),'YData',ydata);
    end
    
    
    % Replace all y values of adjacent value
    h = flipud(findobj(gca,'Tag','Upper Adjacent Value'));
    for j=1:length(h);
        ydata = get(h(j),'YData');
        ydata(:) = means(j)+numOfSig*stds(j);
        set(h(j),'YData',ydata);
    end
    
    % Replace lower end y value of whisker
    h = flipud(findobj(gca,'Tag','Lower Whisker'));
    for j=1:length(h);
        ydata = get(h(j),'YData');
        ydata(1) = means(j)-numOfSig*stds(j);
        set(h(j),'YData',ydata);
    end
    
    % Replace all y values of adjacent value
    h = flipud(findobj(gca,'Tag','Lower Adjacent Value'));
    for j=1:length(h);
        ydata = get(h(j),'YData');
        ydata(:) = means(j)-numOfSig*stds(j);
        set(h(j),'YData',ydata);
    end
    
    set(gca,'XTickLabel',Labels);
    set(gca,'XTickLabelRotation',45)
end