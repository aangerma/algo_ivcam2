function isValid = validFrame(ptsWithZ,calibParams)

if ~isempty(calibParams.gnrl.cbGridSz)
    isValid = ~any(vec(isnan(ptsWithZ)));
else
    validCBPoints = all(~isnan(ptsWithZ(:,[1,4,5])),2);
    validCBPoints = reshape(validCBPoints,20,28);
    validRows = any((validCBPoints),2);
    validCols = any((validCBPoints),1);
    validCBPoints = validCBPoints(validRows,validCols);
    isValid = sum(validCBPoints(:)) > 0;
end

end