function table = fillStartNans(table)
    for i = 1:size(table,2)
        ni = find(~isnan(table(:,i)),1);
        if ni>1
            table(1:ni-1,i) = table(ni,i);
        end
    end
end