function [udistLUT,udistRegs,maxPixelDisplacement] = calibUndistAng2xyBugFix(fw,runParams)

% When fixing the ang2xy bug using the undististortion table the following
% steps need to be taken:
% 1. Take a grid of x-y coordinates in the image plane.
% 2. Transform the x-y coordinates into angx-angy. Using a fixed xy2ang (with the bug fixed). 
% 3. Transform the angx-angy into x-y. Using the bugged ang2xy.
% 4. Find an undistortion table that moves the bugged x-y coordinates to
%    their true location.
if exist(fullfile(runParams.outputFolder,'AlgoInternal','tpsUndistModel.mat'), 'file') == 2
    load(fullfile(runParams.outputFolder,'AlgoInternal','tpsUndistModel.mat')); % loads undistTpsModel
else
    tpsUndistModel = [];
end



regs = fw.get();

udistRegs.FRMW.xfov = regs.FRMW.xfov;
udistRegs.FRMW.yfov = regs.FRMW.yfov;

% For the current regs, the image plane should be made from the values at
% the locations xbug/ybug. We need to translate xbug to xg and the same for
% y.
[udistLUT,~,~] = Calibration.Undist.generateUndistTablesFromGridPointsOnly(regs,tpsUndistModel);
% [udistLUT,~,~] = Calibration.Undist.generateUndistTablesFromGridPointsOnly(regs,runParams); 

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
% % %     v = Calibration.aux.xy2vec(xg,yg,regs); % for each pixel, get the unit vector in space corresponding to it.
% % %     [angxg,angyg] = Calibration.aux.vec2ang(v,origregs);
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
[angxPostPolyUndist,angyPostPolyUndist] = Calibration.Undist.applyPolyUndistAndPitchFix(angx,angy,regs);
% Transform the angx-angy into x-y. Using the bugged ang2xy:
v = Calibration.aux.ang2vec(angxPostPolyUndist,angyPostPolyUndist,regs);
if ~isempty(tpsUndistModel)% 2D Undist - 
    v = Calibration.Undist.undistByTPSModel( v',tpsUndistModel)';
end
[xg,yg] = Calibration.aux.vec2xy(v,regs);

% Pipe flow
[xbug,ybug] = Calibration.aux.ang2xySF(angx,angy,regs);
% Apply the lut to the bugged x-y and calculate the displacement error:
luts.FRMW.undistModel = udistLUT;
[autogenLuts] = Pipe.DIGG.FRMW.BuildUndistLut(regs,luts);
luts = Firmware.mergeRegs(luts,autogenLuts);
[ xnew,ynew ] = Pipe.DIGG.undist( xbug*2^15,ybug*2^15,regs,luts,[],[] );
xnew = single(xnew)/2^15;
ynew = single(ynew)/2^15;
xnew = xnew(:);
ynew = ynew(:);


validP = (xnew(:) >=0 & xnew(:) <= regs.GNRL.imgHsize) & (ynew(:) >=0 & ynew(:) <= regs.GNRL.imgVsize) | ...
        (xg(:) >=0 & xg(:) <= regs.GNRL.imgHsize) & (yg(:) >=0 & yg(:) <= regs.GNRL.imgVsize);

eMatPost = sqrt((xnew-xg).^2 + (ynew-yg).^2);
maxPixelDisplacement = max(eMatPost(validP));

%%
ff = Calibration.aux.invisibleFigure;
quiver(xnew(:),ynew(:),xg(:)-xnew(:),yg(:)-ynew(:)); 
title(sprintf('Displacement Vector Per Pixel - Post Fix\n max error %.2f',max(eMatPost(:))));
Calibration.aux.saveFigureAsImage(ff,runParams,'Undist','DisplacementErrors');

ff = Calibration.aux.invisibleFigure;
plot(xbug,ybug,'r*')
hold on
plot(xnew,ynew,'g*')
hold on
rectangle('position',[0 0 regs.GNRL.imgHsize regs.GNRL.imgVsize]);
title(sprintf('Before(r) & After(g) Undistort Block'));
Calibration.aux.saveFigureAsImage(ff,runParams,'Undist','BeforeAfterUndist');




end

