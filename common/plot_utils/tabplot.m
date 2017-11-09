function ax = tabplot(tabNum,f)
%bulid tabs on figure to plot in

if(nargin < 2)
    f = gcf;
end

%% get tab group
if(isempty(f.Children)) %first tab in figure
    tg = uitabgroup('Parent',f);
elseif(isa(f.Children,'matlab.ui.container.TabGroup'))
    tg = f.Children;
else %figure is occupied
    clf;
    tg = uitabgroup('Parent',f);
end

%% get current tab or set a new one
tabNums = cellfun(@(y) str2double(y), (( arrayfun(@(x) x.Title ,tg.Children,'uni',0)  )    )    );

if(nargin == 0) %get the next avialable tab number
    if(isempty(tabNums))
        tabNum = 1;
    else
        tabNum = max(tabNums) + 1;
    end
end

if(any(tabNums==tabNum)) %given tab num exist
    thistab = tg.Children(tabNums==tabNum);
    ax = thistab.Children;
else %build a new tab
    thistab = uitab(tg,'Title',num2str(tabNum)); % build tab
    ax = axes('Parent',thistab);
end

tg.SelectedTab = thistab; %put in front
end