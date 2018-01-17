function [uxg,uyg,undistx,undisty]=undistFromImg(fldr,verbose)
if(~exist('verbose','var'))
    verbose=false;
end
s=io.readZIC(fldr,1);
im=s.i;
[e,s,d]=Calibration.aux.evalProjectiveDisotrtion(im);
[udistLUT,uxg,uyg,undistx,undisty]=Calibration.aux.generateUndistTables(s,d,size(im));
io.writeBin(fullfile(fldr,filesep,'FRMWundistModel.bin32'),udistLUT);
if(verbose)
    %%
    figure(sum('filecalib'));
    clf;
    imagesc(im);
    colorbar gray
    quiver(xg,yg,undistx,undisty);
    title(sprintf('Projective error: %f',e));
end

end

