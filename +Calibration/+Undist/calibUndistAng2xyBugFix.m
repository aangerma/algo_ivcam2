function [udistLUT,maxPixelDisplacement] = calibUndistAng2xyBugFix(regs,verbose)

% When fixing the ang2xy bug using the undististortion table the following
% steps need to be taken:
% 1. Take a grid of x-y coordinates in the image plane.
% 2. Transform the x-y coordinates into angx-angy. Using a fixed xy2ang (with the bug fixed). 
% 3. Transform the angx-angy into x-y. Using the bugged ang2xy.
% 4. Find an undistortion table that moves the bugged x-y coordinates to
%    their true location.

% Made sure ang2xy and xy2ang are inverse of each other after the bug fix:
% [angx,angy] = meshgrid(linspace(-2047,2047,500),linspace(-2047,2047,500));
% [x,y] = localAng2xy(angx,angy,regs,true);
% [angx_,angy_] = localxy2ang(x,y,regs,true);
% assert( max(sqrt((angx(:)-angx_(:)).^2))<=0.01,'ang2xy ang xy2ang aren''t inverse')
% assert( max(sqrt((angy(:)-angy_(:)).^2))<=0.01,'ang2xy ang xy2ang aren''t inverse')


% A grid of x-y coordinates in the image plane:
margin = 10; % In pixels. How far from the image plane to correct the location. 
dp = 10; % In pixels. Pixel grid spacing. Too small a number will provide insufficient number of examples for fixing, too great a number will take too long to compute.
dpy = double(regs.GNRL.imgVsize+2*margin)/round(double(regs.GNRL.imgVsize+2*margin)/dp);% Make sure the range of pixels divide by dp. Thus the pixel grid will be symmetric.
dpx = double(regs.GNRL.imgHsize+2*margin)/round(double(regs.GNRL.imgHsize+2*margin)/dp);% Make sure the range of pixels divide by dp. Thus the pixel grid will be symmetric.

[xg,yg] = meshgrid(-margin:dpy:double(regs.GNRL.imgHsize+margin),-margin:dpx:double(regs.GNRL.imgVsize+margin)); 

% transform to angx-angy. Using the fixed xy2ang:
[angxg,angyg] = Calibration.aux.xy2angSF(xg,yg,regs,true);

% Transform the angx-angy into x-y. Using the bugged ang2xy:
[xbug,ybug] = Calibration.aux.ang2xySF(angxg,angyg,regs,false);

% For the current regs, the image plane should be made from the values at
% the locations xbug/ybug. We need to translate xbug to xg and the same for
% y.

[udistLUT,~,~,~,~]= Calibration.Undist.generateUndistTables([xbug(:),ybug(:)]',[xg(:),yg(:)]',double([regs.GNRL.imgVsize,regs.GNRL.imgHsize]));

% Apply the lut to the bugged x-y and calculate the displacement error:
luts.FRMW.undistModel = udistLUT;
[autogenRegs,autogenLuts] = Pipe.DIGG.FRMW.buildLensLUT(regs,luts);
regs = Firmware.mergeRegs(regs,autogenRegs);
luts = Firmware.mergeRegs(luts,autogenLuts);
[ xnew,ynew ] = Pipe.DIGG.undist( xbug*2^15,ybug*2^15,regs,luts,[],[] );
xnew = single(xnew)/2^15;
ynew = single(ynew)/2^15;

eMatPre = sqrt((xbug-xg).^2 + (ybug-yg).^2);
eMatPost = sqrt((xnew-xg).^2 + (ynew-yg).^2);

maxPixelDisplacement = max(eMatPost(:));

if verbose
    ff = figure;
    subplot(121)
    quiver(xbug(:),ybug(:),xg(:)-xbug(:),yg(:)-ybug(:),'autoscale','off'); title(sprintf('Displacement Vector Per Pixel - Pre Fix\n max error %.2f',max(eMatPre(:))));
    subplot(122)
    quiver(xnew(:),ynew(:),xg(:)-xnew(:),yg(:)-ynew(:),'autoscale','off'); title(sprintf('Displacement Vector Per Pixel - Post Fix\n max error %.2f',max(eMatPost(:))));
    close(ff);
end



end

