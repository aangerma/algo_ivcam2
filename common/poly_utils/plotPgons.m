function plotPgons(varargin)
pgons = varargin{1};
if(any(size(pgons{1})==1))
    pgons= cellfun(@(x) [real(x(:)) imag(x(:))],pgons,'uni',false);
end
if(size(pgons{1},1)==2)
    pgons= cellfun(@(x) x',pgons,'uni',false);
end
if(isempty(findstrcell('color',varargin(2:end))))
    c = lines(length(pgons));
else
    c = [];
end
if(strcmpi(varargin{end},'printIndex'))
    printIndex = true;
     varargin = varargin(1:end-1);
else
    printIndex = false;
end

hold on

for i=1:length(pgons)
    if(~isempty(c))
        plot(pgons{i}(:,1),pgons{i}(:,2),'color',c(i,:),varargin{2:end});
    else
        plot(pgons{i}(:,1),pgons{i}(:,2),varargin{2:end});
    end
    if(printIndex)
        text(pgons{i}(1,1),pgons{i}(1,2),sprintf('%d',i));
    end
end
hold off
end