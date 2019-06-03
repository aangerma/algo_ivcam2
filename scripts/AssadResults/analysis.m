% Assad tester results 

T = readtable("\\ger\ec\proj\ha\RSG\SA_3DCam\System\IVCAM2.0\Testers\Thermal_Val_Tester_Results\Thermal_Validation_F9090149_05-07-2019_15-34-46\AllResults_Table_05-07-2019_16-22-54.xls");
vNames = T.Properties.VariableNames;

xVec = T.LDDTemp;
subVec = 1:(numel(xVec)-1);
figure,
for i = 6:numel(vNames)
    yVec = T.(vNames{i});
    if iscell(yVec(1))
       continue; 
    end
    tabplot;
    plot(xVec(subVec),yVec(subVec));
    vN = strrep(vNames{i},'_',' ');
    str = sprintf('%s over LDDTemp',vN);
    title(str);
    grid on;
    a = axis;
    a(3) = min(a(3),0);
    axis(a);
    xlabel('LDDTemp')
    ylabel(vN)
    
end

T.Properties.VariableNames


LDDTemp = 

figure,

