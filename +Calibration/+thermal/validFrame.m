function isValid = validFrame(ptsWithZ,calibParams)

if ~isempty(calibParams.gnrl.cbGridSz)
    isValid = ~any(vec(isnan(ptsWithZ)));
else
    validCBPoints = all(~isnan(ptsWithZ),2);
    validCBPoints = reshape(validCBPoints,20,28);
    validRows = find(any((validCBPoints),2));
    validCols = find(any((validCBPoints),1));
    validCBPoints = validCBPoints(validRows,validCols);
    isValid = all(vec(validCBPoints));
    
end


end