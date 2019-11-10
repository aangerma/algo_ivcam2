basePath = 'C:\temp\rangeByTemp'
files = dir(basePath)
files = files(~[files.isdir])
for iter = 1:numel(files)
    filePath = fullfile(basePath, files(iter).name);
    load(filePath);
    A = [mTemp.lddTmptr; mTemp.maTmptr; ones(size(mTemp))]';
        
    x = (A'*A)\(A'*zVals')
    
    figure;
    hold on;
    yyaxis left;
    plot([mTemp.maTmptr]);
    plot([mTemp.lddTmptr]);
    plot([mTemp.apdTmptr]);
    yyaxis right;
    plot(zVals);
    legend('maTemp', 'lddTemp', 'apdTemp', 'r');
    
    figure;
    hold on;
    yyaxis left;
    plot(zVals);
    yyaxis right;
    plot(zVals'-A*x, 'r');
    legend('r', 'delay');
    
    display(x)
    
end

