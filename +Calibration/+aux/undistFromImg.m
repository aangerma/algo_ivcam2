function [udistLUT,e]=undistFromImg(im,verbose)
if(~exist('verbose','var'))
    verbose=false;
end
[e,s,d]=Calibration.aux.evalProjectiveDisotrtion(im);
[udistLUT,uxg,uyg,undistx,undisty]=Calibration.aux.generateUndistTables(s,d,size(im));
if(verbose)
    %%
    figure(sum(mfilename));
    clf;
    subplot(121)
    imagesc(im);
    axis image
    colormap gray
    hold on
    quiver(s(1,:),s(2,:),d(1,:)-s(1,:),d(2,:)-s(2,:));
    quiver(uxg,uyg,undistx,undisty);
    hold off
    title(sprintf('Projective error: rms=%f,max=%f',e,max(sqrt(sum((d-s).^2,2)))));
    subplot(122)
    
    quiver(s(1,:)*0,s(2,:)*0,d(1,:)-s(1,:),d(2,:)-s(2,:),0);
    
    axis square
end

end

