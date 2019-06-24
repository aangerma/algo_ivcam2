function [udistLUT,udistRegs,maxPixelDisplacement] = calibUndistAng2xyBugFix(fw,calibParams,runParams)

% When fixing the ang2xy bug using the undististortion table the following
% steps need to be taken:
% 1. Take a grid of x-y coordinates in the image plane.
% 2. Transform the x-y coordinates into angx-angy. Using a fixed xy2ang (with the bug fixed). 
% 3. Transform the angx-angy into x-y. Using the bugged ang2xy.
% 4. Find an undistortion table that moves the bugged x-y coordinates to
%    their true location.
regs = fw.get();
origregs = regs;

FE = [];
if calibParams.fovExpander.valid
    FE = calibParams.fovExpander.table;
end
if ~isempty(FE)
    udistRegs.FRMW.xfov = interp1(FE(:,1),FE(:,2),regs.FRMW.xfov/2)*2;
    udistRegs.FRMW.yfov = interp1(FE(:,1),FE(:,2),regs.FRMW.yfov/2)*2;
    fw.setRegs(udistRegs,'');
    regs = fw.get();
else
    udistRegs.FRMW.xfov = regs.FRMW.xfov;
    udistRegs.FRMW.yfov = regs.FRMW.yfov;
end

% For the current regs, the image plane should be made from the values at
% the locations xbug/ybug. We need to translate xbug to xg and the same for
% y.
[udistLUT,~,~] = Calibration.Undist.generateUndistTablesFromGridPointsOnly(regs,origregs,FE);

% % % 
% % % % A grid of x-y coordinates in the image plane:
% % % margin = 10; % In pixels. How far from the image plane to correct the location. 
% % % dp = 10; % In pixels. Pixel grid spacing. Too small a number will provide insufficient number of examples for fixing, too great a number will take too long to compute.
% % % dpy = double(regs.GNRL.imgVsize+2*margin)/round(double(regs.GNRL.imgVsize+2*margin)/dp);% Make sure the range of pixels divide by dp. Thus the pixel grid will be symmetric.
% % % dpx = double(regs.GNRL.imgHsize+2*margin)/round(double(regs.GNRL.imgHsize+2*margin)/dp);% Make sure the range of pixels divide by dp. Thus the pixel grid will be symmetric.
% % % 
% % % [xg,yg] = meshgrid(-margin:dpx:double(regs.GNRL.imgHsize+margin),-margin:dpy:double(regs.GNRL.imgVsize+margin)); 
% % % 
% % % % transform to angx-angy. Using the fixed xy2ang:
% % % if ~isempty(FE)
% % %     v = Calibration.aux.xy2vec(xg,yg,regs); % for each pixel, get the unit vector in space corresponding to it.
% % %     [angxg,angyg] = Calibration.aux.vec2ang(v,origregs,FE);
% % % else
% % %     [angxg,angyg] = Calibration.aux.xy2angSF(xg+0.5,yg+0.5,origregs,true);
% % % end
% % % 
% % % [angxPrePolyUndist,angyPrePolyUndist] = Calibration.Undist.inversePolyUndistAndPitchFix(angxg,angyg,regs);
% % % 
% % % [xNoPolyUndist,yNoPolyUndist] = Calibration.aux.ang2xySF(angxPrePolyUndist,angyPrePolyUndist,regs,[],1);
% % % undistRms = rms(reshape(sqrt((xg - xNoPolyUndist).^2 + (yg - yNoPolyUndist).^2),[],1));
% % % 
% % % % Transform the angx-angy into x-y. Using the bugged ang2xy:
% % % [xbug,ybug] = Calibration.aux.ang2xySF(angxPrePolyUndist,angyPrePolyUndist,regs,[],false);
% % % % Apply the lut to the bugged x-y and calculate the displacement error:
% % % luts.FRMW.undistModel = udistLUT;
% % % [autogenRegs,autogenLuts] = Pipe.DIGG.FRMW.buildLensLUT(regs,luts);
% % % regs = Firmware.mergeRegs(regs,autogenRegs);
% % % luts = Firmware.mergeRegs(luts,autogenLuts);
% % % [ xnew,ynew ] = Pipe.DIGG.undist( xbug*2^15,ybug*2^15,regs,luts,[],[] );
% % % xnew = single(xnew)/2^15;
% % % ynew = single(ynew)/2^15;
% % % 
% % % % eMatPre = sqrt((xbug-xg).^2 + (ybug-yg).^2);
% % % eMatPost = sqrt((xnew-xg).^2 + (ynew-yg).^2);
% % % 
% % % maxPixelDisplacement = max(eMatPost(:));



nPoints = 50;
[angx,angy] = meshgrid(linspace(-2047,2047,nPoints),linspace(-2047,2047,nPoints)); 

% Perfect flow
[angxPostPolyUndist,angyPostPolyUndist] = Calibration.Undist.applyPolyUndistAndPitchFix(angx,angy,origregs);
% Transform the angx-angy into x-y. Using the bugged ang2xy:
if ~isempty(FE)
    v = Calibration.aux.ang2vec(angxPostPolyUndist,angyPostPolyUndist,origregs,FE);
    [xg,yg] = Calibration.aux.vec2xy(v,regs);
else
    [xg,yg] = Calibration.aux.ang2xySF(angxPostPolyUndist,angyPostPolyUndist,origregs,[],true);
end

% Pipe flow
[xbug,ybug] = Calibration.aux.ang2xySF(angx,angy,regs,[],false);
% Apply the lut to the bugged x-y and calculate the displacement error:
luts.FRMW.undistModel = udistLUT;
[autogenRegs,autogenLuts] = Pipe.DIGG.FRMW.buildLensLUT(regs,luts);
regs = Firmware.mergeRegs(regs,autogenRegs);
luts = Firmware.mergeRegs(luts,autogenLuts);
[ xnew,ynew ] = Pipe.DIGG.undist( xbug*2^15,ybug*2^15,regs,luts,[],[] );
xnew = single(xnew)/2^15;
ynew = single(ynew)/2^15;
xnew = xnew(:);
ynew = ynew(:);


eMatPost = sqrt((xnew-xg).^2 + (ynew-yg).^2);
maxPixelDisplacement = max(eMatPost(:));



%%
ff = Calibration.aux.invisibleFigure;
quiver(xnew(:),ynew(:),xg(:)-xnew(:),yg(:)-ynew(:),'autoscale','off'); 
title(sprintf('Displacement Vector Per Pixel - Post Fix\n max error %.2f',max(eMatPost(:))));
Calibration.aux.saveFigureAsImage(ff,runParams,'Undist','DisplacementErrors');

if 0
    
    
end



end

