function [udistLUT,e]=undistFromImg(im,verbose)
if(~exist('verbose','var'))
    verbose=false;
end
[e,s,d]=Calibration.aux.evalProjectiveDisotrtion(im);
[udistLUT,uxg,uyg,undistx,undisty]=Calibration.aux.generateUndistTables(s,d,size(im));
if(verbose)
    %%
    figure(sum('filecalib'));
    clf;
    imagesc(im);
    colormap gray
    hold on
    quiver(uxg,uyg,undistx,undisty);
    hold off
    title(sprintf('Projective error: %f',e));
end

end

