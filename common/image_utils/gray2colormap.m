function imgRGB = gray2colormap(imgGRAY01,cm)
nanLocs = isnan(imgGRAY01);
imgGRAY01 = max(0,min(1,imgGRAY01));
cm=[0 0 0 ;cm];
cmsz = size(cm,1);
imgv=round(imgGRAY01(:)*(cmsz-2)+2);
imgv(nanLocs)=1;
imgv = cm(imgv,:);
imgRGB = reshape(imgv,[size(imgGRAY01) 3]);
end