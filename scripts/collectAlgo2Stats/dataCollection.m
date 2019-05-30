cal = 1;
headDir = '\\143.185.124.250\tester data\IDC Data\IVCAM\L515\Calibration\FW 1.2.12.201';

if cal
    targetName = 'data.mat';
    neighbourName = 'figures';
else
    targetName = 'validationData.mat';
    neighbourName = 'figures';
end


flist = findFiles(headDir);


mightMatch = contains(flist,targetName);
flistNext = flist(mightMatch);

ai = 1;
for i = 1:numel(flistNext)
   x = load( flistNext{i});
   if isfield(x.data,'results')
        algo2results(ai) = x.data.results;
        ai = ai + 1;
   end
end

save algo2results.mat algo2results

fn = fieldnames(algo2results);
for i = 1:numel(fn)
    avgStd.(fn{i}) = [mean([algo2results.(fn{i})]);std([algo2results.(fn{i})])];
    
end

T = struct2table(avgStd);
writetable(T,'algo2Res.xls');