function tableNoInnerNans = fillInnerNans(table)
tableNoInnerNans = table;
for iRow = 1:size(table,2)
    col = table(:, iRow);
    nanRows = isnan(col);
    rowId = (1:size(table, 1))';
    tableValid = col(~nanRows);
    rowValid = rowId(~nanRows);
    rowInvalid = rowId(nanRows);
    newVals = interp1q(rowValid, tableValid, rowInvalid);
    tableNoInnerNans(nanRows, iRow) = newVals;
end
