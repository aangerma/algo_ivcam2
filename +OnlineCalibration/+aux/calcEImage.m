
function [E] = calcEImage(yuy2,options)
    tic;
    if strcmp(options.edgeMethod,'maxDiff')
        yuy2Med = medfilt2(single(yuy2),[5,5]);
        E = zeros(size(yuy2Med));
        w = 3;
        indx = Utils.indx2col(size(E),[w w]);
        indx = reshape(indx,[w^2 size(E)]);
        yuy2Box = yuy2Med(indx);
        E = squeeze(max(abs(single(yuy2Box)-single(reshape(yuy2,1,size(yuy2,1),size(yuy2,2))))));
    elseif strcmp(options.edgeMethod,'sobel')
        [Ix,Iy] = imgradientxy(single(yuy2));% Sobel image gradients [-1,0,1;-2,0,2;-1,0,1]
        E = sqrt(Ix.^2+Iy.^2);
    else
        error('Unknown EdgeMethod type (%s)',options.EdgeMethod);
    end
    
    time = toc;
    fprintf('calcEImage took %3.2f seconds\n',time);
    

    
    
end