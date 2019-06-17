function [cbCorners,cornersValid,params] = prepareData(im,rgbs,calibParams)
    %PREPAREDATA extract the feature points form the RGB and the IR
    %according to the calibParams for the calibration
    
    captures = {calibParams.dfz.captures.capture(:).type};
    captures = captures(find(~strncmpi(captures,'shortRange',10))); % remove shortRange not relvent for RGB calibration 
    cbCorners = cell(length(captures),3);
    cornersValid = zeros(length(captures),1,'logical');
    for i = 1:numel(captures)
        cap = calibParams.dfz.captures.capture(i);
        targetInfo = targetInfoGenerator(cap.target);
        targetInfo.cornersX = 20;
        targetInfo.cornersY = 28;
        pts = Calibration.aux.CBTools.findCheckerboardFullMatrix(im(i).i, 0);
        cbCorners{i,1} = reshape(pts,[],2);
        pts = Calibration.aux.CBTools.findCheckerboardFullMatrix(rgbs{i}, 0,1);
        cbCorners{i,2} = reshape(pts,[],2);
        pt3D = create3DCorners(targetInfo)';
        cbCorners{i,3} = pt3D(:,[2 1 3]);
        cornersValid(i) = sum(~isnan(cbCorners{i,1}(:,1))) > 0 && sum(~isnan(cbCorners{i,2}(:,1))) > 0;
    end
    
    params = [];
    params.RGBImageSize = flip(size(rgbs{end}));
    params.LRImageSize = flip(size(im(end).i));
    params.LensModel.distortionNumRGB = 5*calibParams.rgb.rgbDistoration;
    params.LensModel.distortionNumLR = 0;
    params.LensModel.arePixelsSquare = logical(calibParams.rgb.arePixelsSquare);
end

