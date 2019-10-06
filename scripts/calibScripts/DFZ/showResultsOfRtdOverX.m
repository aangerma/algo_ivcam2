clear
load('resultsWithRTDOverXFixNonSym.mat');
fnames = fieldnames(results);
for f = 1:numel(fnames)
   value(f,1) = mean([results.(fnames{f})]); 
end
delaysWithFix = sDelay;
load('resultsWithoutRTDOverXFixNonSym.mat');
for f = 1:numel(fnames)
   value(f,2) = mean([results.(fnames{f})]); 
end
delaysWithoutFix = sDelay;


T = array2table(value,'rowNames',fnames ,'VariableNames',{'rtdOverX','v1936'});
writetable(T,'rtdOverX_5_units_results_poly5_nonsym.xlsx','WriteRowNames',true,'Sheet', 1');
delaysWithoutFix - delaysWithFix
