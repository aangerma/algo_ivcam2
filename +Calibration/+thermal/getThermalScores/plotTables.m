dataPaths = {"\\ger\ec\proj\ha\RSG\SA_3DCam\TMund\F9010093\1.25Gui Runs\F9010093\TC07\data.mat";...
    "\\ger\ec\proj\ha\RSG\SA_3DCam\TMund\F9010093\1.25Gui Runs\F9010093\TC08_close_air_vents\data.mat";...
    "\\ger\ec\proj\ha\RSG\SA_3DCam\TMund\F9010093\1.25Gui Runs\F9010093\TC08_thermostream_run1\data.mat";...
    "\\ger\ec\proj\ha\RSG\SA_3DCam\TMund\F9010093\1.25Gui Runs\F9010093\TC09_thermostream_run2\data.mat";...
    "\\ger\ec\proj\ha\RSG\SA_3DCam\TMund\F9010093\1.25Gui Runs\F9010093\TC11_thermostream_run3\data.mat";...
    "\\ger\ec\proj\ha\RSG\SA_3DCam\TMund\F9010093\1.25Gui Runs\F9010093\TC13\data.mat"};

legends = {'TC07','TC08_close_air_vents','TC08_thermostream_run1','TC09_thermostream_run2','TC11_thermostream_run3','TC13'};
titles = {'dsmXscale','dsmYscale','dsmXoffset','dsmYoffset','RTD Offset'};


for i = 1:numel(dataPaths)
    load(dataPaths{i});
    for k = 1:5
        figure(k);
        plot(32:79,data.processed.table(:,k));
        hold on;
        title(titles{k})
        if i == numel(dataPaths)
           legend(legends);
        end
    end
end