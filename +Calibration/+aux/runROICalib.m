function [regs] = runROICalib(hw, verbose)

frame = hw.getFrame(10);

sz = size(frame.i);
invPixels = isnan(frame.i);

vCrop = round(sz(1)*0.15);

imgVcrop = invPixels(vCrop:end-vCrop,:);
vBounds = diff(double(sum(imgVcrop,1)==0));

iLeft = find(vBounds == 1);
if isempty(iLeft)
    marginL = 0;
else
    marginL = iLeft;
end
    
iRight = find(vBounds == -1);
if isempty(iRight)
    marginR = 0;
else
    marginR = sz(2)-iRight;
end

imgHcrop = invPixels(:,marginL+1:end-marginR);
hBounds = diff(double(sum(imgHcrop,2)==0));

iTop = find(hBounds == 1);
if isempty(iTop)
    marginT = 0;
else
    marginT = iTop;
end

iBottom = find(hBounds == -1);
if isempty(iBottom)
    marginB = 0;
else
    marginB = sz(1)-iBottom;
end

%regs = struct();

rx = sz(2) / (sz(2) - marginR - marginL);
regs.FRMW.marginR = int16(ceil(marginR * rx));
regs.FRMW.marginL = int16(ceil(marginL * rx));
regs.FRMW.xres = uint16(sz(2)) + uint16(regs.FRMW.marginR) + uint16(regs.FRMW.marginL);
assert(int16(regs.FRMW.xres) - regs.FRMW.marginR - regs.FRMW.marginL == sz(2), 'wrong xres to be set');

ry = sz(1) / (sz(1) - marginT - marginB);
regs.FRMW.marginT = int16(ceil(marginT * ry));
regs.FRMW.marginB = int16(ceil(marginB * ry));
regs.FRMW.yres = uint16(sz(1)) + uint16(regs.FRMW.marginT) + uint16(regs.FRMW.marginB);
assert(int16(regs.FRMW.yres) - regs.FRMW.marginT - regs.FRMW.marginB == sz(1), 'wrong yres to be set');

end

