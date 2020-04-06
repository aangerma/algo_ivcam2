function [cbCorners,cornersValid,params] = prepareData(im,rgbs,calibParams)
    %PREPAREDATA extract the feature points form the RGB and the IR
    %according to the calibParams for the calibration
    
    captures = {calibParams.dfz.captures.capture(:).type};
    captures = captures(find(~strncmpi(captures,'shortRange',10))); % remove shortRange not relvent for RGB calibration 
    cbCorners = cell(length(captures),3);
    cornersValid = zeros(length(captures),1,'logical');
%     figure
    for i = 1:numel(captures)
        cap = calibParams.dfz.captures.capture(i);
        targetInfo = targetInfoGenerator(cap.target);
        targetInfo.cornersX = 20;
        targetInfo.cornersY = 28;
        CB = CBTools.Checkerboard (im(i).i, 'targetType', 'checkerboard_Iv2A1');  
        pts = CB.getGridPointsMat;
        if all(isnan(pts(:)))
            Calibration.aux.CBTools.interpretFailedCBDetection(im(i).i, sprintf('UV mapping IR image %d',i));
        end
        pts = pts - 1;
        cbCorners{i,1} = reshape(pts,[],2);
%         tabplot; imagesc(im(i).i); hold on, plot(pts(:,:,1),pts(:,:,2),'r*');
        CB = CBTools.Checkerboard (rgbs{i}, 'targetType', 'checkerboard_Iv2A1','rgbImageFlag',true);  
        pts = CB.getGridPointsMat;
        if all(isnan(pts(:)))
            Calibration.aux.CBTools.interpretFailedCBDetection(rgbs{i}, sprintf('UV mapping RGB image %d',i));
        end
        pts = pts - 1;
        cbCorners{i,2} = reshape(pts,[],2);
        pt3D = create3DCorners(targetInfo)';
        cbCorners{i,3} = pt3D(:,[2 1 3]);
        cornersValid(i) = sum(~isnan(cbCorners{i,1}(:,1))) > 0 && sum(~isnan(cbCorners{i,2}(:,1))) > 0;
%         tabplot; imagesc(rgbs{i}); hold on, plot(pts(:,:,1),pts(:,:,2),'r*');
    end
    
    params = [];
    params.RGBImageSize = flip(size(rgbs{end}));
    params.LRImageSize = flip(size(im(end).i));
    params.LensModel.distortionNumRGB = 5*calibParams.rgb.rgbDistoration;
    params.LensModel.distortionNumLR = 0;
    params.LensModel.arePixelsSquare = logical(calibParams.rgb.arePixelsSquare);
    params.distFromPP4distortion1 = calibParams.rgb.distFromPP4distortion1;
    params.distFromPP4distortion2 = calibParams.rgb.distFromPP4distortion2;
end

