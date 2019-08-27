function [ Ttag ] = dfzResultsToTable( results )

    T = struct2table(results);
    T.Properties.RowNames = T.Name;
    T.Name = [];
    YourArray = table2array(T);
    Ttag = array2table(YourArray.');
    Ttag.Properties.RowNames = T.Properties.VariableNames;
    Ttag.Properties.VariableNames = T.Properties.RowNames;
end

