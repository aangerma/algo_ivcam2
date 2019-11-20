function [ spArr ] = spherical2xy( spArr,regs, calibParams )
%SPHERICAL2XY This function calculates the xy coordinates of the checkerboard corners in sperical image and transforms it to the regular image plane. 
%   Receives:
%     spArr - an array of spherical frames.
%     regs - camera configuration. Tells us howto transform from angx/angy to xy.
%   Returns:
%      spArr that include a new fields:
%      cbCorners - an NxMx2 array that corresponds to the checkerboard corners and contains the xy coordinates of each point in the rectified image. NxM is the CB dimensions. 
        
warning('off','vision:calibrate:boardShouldBeAsymmetric'); % Supress checkerboard warning
for i = 1:numel(spArr)    
    spArr(i).cbCorners = spherical2xySingle( spArr(i),regs,calibParams );
end

end

function [ cbCorners ] = spherical2xySingle( sp,regs )
%SPHERICAL2XY Applies to a single image.

CB = CBTools.Checkerboard (normByMax(ddouble(sp.i)),'expectedGridSize',[9,13]);  
p = CB.getGridPointsList;
p = p-1; % coordinates should start from 0.
yy = double(p(:,2));
xx = double(p(:,1)*4);
xx = xx-double(regs.DIGG.sphericalOffset(1));
yy = yy-double(regs.DIGG.sphericalOffset(2));
xx = xx*2^10;%bitshift(xx,+12-2);
yy = yy*2^12;%bitshift(yy,+12);
xx = xx/double(regs.DIGG.sphericalScale(1));
yy = yy/double(regs.DIGG.sphericalScale(2));
angx = single(xx);
angy = single(yy);

[x,y] = Calibration.aux.vec2xy(Calibration.aux.ang2vec(angx,angy,regs), regs);
x = double(regs.GNRL.imgHsize) - reshape(x,9,13,1);
y = double(regs.GNRL.imgVsize) - reshape(y,9,13,1);
x = rot90(x,2); % Make sure the order is TopLeft - BottomRight
y = rot90(y,2);
cbCorners = cat(3,x,y);


end