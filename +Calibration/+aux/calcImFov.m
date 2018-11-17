function [ imFovX,imFovY ] = calcImFov( fw )
%CALCIMFOV calculation of the fov visible in the image plane - includs applying ROI.
regs = fw.get();
sz = double([regs.GNRL.imgHsize,regs.GNRL.imgVsize]);

imFovX = -atand(0*regs.DEST.p2axa + regs.DEST.p2axb)+atand((sz(1)-1)*regs.DEST.p2axa + regs.DEST.p2axb);
imFovY = -atand(0*regs.DEST.p2aya + regs.DEST.p2ayb)+atand((sz(2)-1)*regs.DEST.p2aya + regs.DEST.p2ayb);

end

