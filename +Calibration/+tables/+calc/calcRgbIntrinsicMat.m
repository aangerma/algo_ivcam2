function Kn = calcRgbIntrinsicMat(rgbCalibData, rgbImageSize)

Kn = rgbCalibData.color.Kn;
for iRow = 1:2
    Kn(iRow,iRow) = Kn(iRow,iRow)*rgbImageSize(iRow)/2;
    Kn(iRow,3) = (Kn(iRow,3)+1)*rgbImageSize(iRow)/2;
end
    