function K = calcRgbIntrinsicMat(normalizedK, rgbImageSize)

K = normalizedK;
for iRow = 1:2
    K(iRow,iRow) = K(iRow,iRow)*rgbImageSize(iRow)/2;
    K(iRow,3) = (K(iRow,3)+1)*rgbImageSize(iRow)/2;
end
    