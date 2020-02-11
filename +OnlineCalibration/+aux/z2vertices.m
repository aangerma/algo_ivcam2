
function V = z2vertices(Z,validMask,camerasParams)
    [X,Y] = meshgrid(1:size(Z,2),1:size(Z,1));
    X = X(validMask)-1;
    Y = Y(validMask)-1;
    V = (camerasParams.Kdepth\[X(:)';Y(:)';ones(1,numel(Z(validMask)))])';
    V = V.*Z(validMask)/single(camerasParams.zMaxSubMM);
end
