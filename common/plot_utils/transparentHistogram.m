function  h1 = transparentHistogram(data,bins,color,normalization)
    if ~exist('color','var')
        color = rand(1,3);
        %         normalization = 'probability';
    end
    if ~exist('normalization','var')
        normalization = 'count';
        %         normalization = 'probability';
    end
    hold on
    histogram(data,bins,'normalization',normalization);
    h1 = gca;
    h = findobj(h1,'Type','patch');
    set(h,'FaceColor',color,'EdgeColor','w','facealpha',0.55)
    
    
end