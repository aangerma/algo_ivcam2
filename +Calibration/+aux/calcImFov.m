function [ results,calibPassed ] = calcImFov( fw ,results,calibParams,fprintff)
%CALCIMFOV calculation of the fov visible in the image plane - includs applying ROI.
regs = fw.get();
sz = double([regs.GNRL.imgHsize,regs.GNRL.imgVsize]);

results.imFovX = -atand(0*regs.DEST.p2axa + regs.DEST.p2axb)+atand((sz(1)-1)*regs.DEST.p2axa + regs.DEST.p2axb);
results.imFovY = -atand(0*regs.DEST.p2aya + regs.DEST.p2ayb)+atand((sz(2)-1)*regs.DEST.p2aya + regs.DEST.p2ayb);


calibPassed = inRange(results.imFovX,calibParams.errRange.imFovX) && inRange(results.imFovY,calibParams.errRange.imFovY);
      
if calibPassed
    fprintff('[v] Image fovX/Y: [%3.3g,%3.3g].\n',results.imFovX,results.imFovY);
else
    fprintff('[v] FovX/Y failed. Image fovX/Y: [%3.3g,%3.3g]. RangeX: [%3.3g,%3.3g]. RangeY: [%3.3g,%3.3g].\n',results.imFovX,results.imFovY,calibParams.errRange.imFovX,calibParams.errRange.imFovY);
end


end
function res = inRange(x,lowHigh)
    res = x<=lowHigh(2) && x>=lowHigh(1);
end

