%{
Usage:
        d = hw.getFrame(10);
        r = Calibration.RegState(hw);
        r.add('DIGGsphericalEn', true);
        r.set();
        dSpherical = hw.getFrame(10);
        r.reset();
        roiRegs = Calibration.roi.runROICalib(d,dSpherical,true);
%}
function [regs] = runROICalib(frame, frameSpherical, useExtraMargins)
extraMarginL=3;
extraMarginR=13;
extraMarginT=3;
extraMarginB=3;

ir = frame.i;
sz = size(ir);
%invPixels = (frame.i==0);

vCrop = round(sz(1)*0.15);
hCrop = round(sz(2)*0.15);

nestMax = findNestMax(frameSpherical.i);
nestMask = (ir <= nestMax);

imgVcrop = nestMask(vCrop:end-vCrop,:);
vBounds = diff(double(sum(imgVcrop,1)==0));

iLeft = find(vBounds == 1, 1);
if (isempty(iLeft) || iLeft > 80) % add 80 to params
    marginL = 0;
else
    marginL = iLeft;
end
    
iRight = find(vBounds == -1, 1,'last');
if (isempty(iRight) || iRight < sz(2) - 80) % add 80 to params
    marginR = 0;
else
    marginR = sz(2)-iRight;
end

imgHcrop = nestMask(:,marginL+1:end-marginR);
hBounds = diff(double(sum(imgHcrop,2)==0));

iTop = find(hBounds == 1, 1);
if (isempty(iTop) || iTop > 80) % add 80 to params
    marginT = 0;
else
    marginT = iTop;
end

iBottom = find(hBounds == -1, 1,'last');
if (isempty(iBottom) || iBottom > sz(2) - 80) % add 80 to params
    marginB = 0;
else
    marginB = sz(1)-iBottom;
end

verbose = 1;
if (verbose)
    figure; imagesc(frame.i); hold on;
    line([marginL marginL], [1 sz(1)], 'Color','red');
    line([sz(2)-marginR sz(2)-marginR], [1 sz(1)], 'Color','red');
    line([1 sz(2)], [marginT marginT], 'Color','red');
    line([1 sz(2)], [sz(1)-marginB sz(1)-marginB], 'Color','red');
end

%regs = struct();

rx = sz(2) / (sz(2) - marginR - marginL);
regs.FRMW.marginR = int16(ceil(marginR * rx))+extraMarginR*useExtraMargins;
regs.FRMW.marginL = int16(ceil(marginL * rx))+extraMarginL*useExtraMargins;
%regs.FRMW.xres = uint16(sz(2)) + uint16(regs.FRMW.marginR) + uint16(regs.FRMW.marginL);
%assert(int16(regs.FRMW.xres) - regs.FRMW.marginR - regs.FRMW.marginL == sz(2), 'wrong xres to be set');

ry = sz(1) / (sz(1) - marginT - marginB);
regs.FRMW.marginT = int16(ceil(marginT * ry))+extraMarginT*useExtraMargins;
regs.FRMW.marginB = int16(ceil(marginB * ry))+extraMarginB*useExtraMargins;
%regs.FRMW.yres = uint16(sz(1)) + uint16(regs.FRMW.marginT) + uint16(regs.FRMW.marginB);
%assert(int16(regs.FRMW.yres) - regs.FRMW.marginT - regs.FRMW.marginB == sz(1), 'wrong yres to be set');

end

function [nestMax] = findNestMax(ir)

sz = size(ir);
vCrop = round(sz(1)*0.15);
irVcrop = ir(vCrop:end-vCrop,:);

vSum = sum(irVcrop, 1);
iColFirstNest = find(vSum ~= 0, 1);

nestFirstCol = ir(:,iColFirstNest);
nestFirstCol = nestFirstCol(nestFirstCol ~= 0);

irFilled = ir;
iColEmpty = (vSum == 0);
irFilled(:,iColEmpty) = nestFirstCol(1);
iColNest = arrayfun(@(x) find(irFilled(:,x)~=0,1,'last'), 1:sz(2));
colNest = irFilled(sub2ind(sz, iColNest, 1:sz(2)));
nestMax = max(colNest) + 2;

end
