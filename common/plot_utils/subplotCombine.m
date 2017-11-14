function subplotCombine(f,subplotnums)
if(nargin==0)
    f = gcf;
end
ax = findobj(get(f,'children'),'Type','Axes');
if(nargin==2)
    pos = zeros(size(ax));
    %sort all subplots by position (upper left is smallest) - numbers are
    %like the order of subplot [ 1 2;
    %                            3 4];
    for i=1:length(ax)
        pos(i) = -ax(i).Position(2)*10000+ax(i).Position(1);
    end
    [~,ind] = sort(pos);
    ax = ax(ind(subplotnums));
end
mn = nan;
mx = nan;
for i=1:length(ax)
    mn = min(mn, ax(i).CLim(1));
    mx = max(mx, ax(i).CLim(2));
end
for i=1:length(ax)
    ax(i).CLim = [mn mx];
end
linkaxes(ax);

end