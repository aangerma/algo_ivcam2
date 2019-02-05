
load('fw.mat');
load('regular.mat');
load('spherical.mat');

[regs,luts] = fw.get();
spregs = regs;
spregs.DEST.depthAsRange = 1;
spregs.DIGG.sphericalEn = 1;

targetInfo = targetInfoGenerator('Iv2A1');
targetInfo.cornersX = 20;
targetInfo.cornersY = 28;
pts = Calibration.aux.CBTools.findCheckerboardFullMatrix(framesSpherical.i, 0);
grid = [size(pts,1),size(pts,2),1];
framesSpherical.pts = pts;
framesSpherical.grid = grid;
framesSpherical.pts3d = create3DCorners(targetInfo)';
framesSpherical.rpt = Calibration.aux.samplePointsRtd(framesSpherical.z,pts,spregs);
    
calibParams = xml2structWrapper('calibParams.xml');
[~,eGeom(1)] = Calibration.aux.calibDFZ(framesSpherical,spregs,calibParams,@fprintf,0,1);
    

calibParams = xml2structWrapper('calibParams.xml');
params.camera.K = reshape([typecast(regs.CBUF.spare,'single'),1],3,3)';
params.camera.zMaxSubMM = 2^double(regs.GNRL.zMaxSubMMExp);
params.target.squareSize = calibParams.validationConfig.cbSquareSz;
params.expectedGridSize = calibParams.validationConfig.cbGridSz;
[eGeom(2), allRes,dbg] = Validation.metrics.gridInterDist(rotFrame180(frames), params);



[vs] = spherical2xyz(framesSpherical,spregs);

[vr,ptsR] = regular2xyz(frames,params);

figure,
plot3(vs(:,1),vs(:,2),vs(:,3),'r*')
hold on
plot3(vr(:,1),vr(:,2),vr(:,3),'g*')



% Take spherical points and translate them to xy:
undistFunc = @(ax,polyVars) ax + ax/2047*polyVars(1)+(ax/2047).^2*polyVars(2)+(ax/2047).^3*polyVars(3);
[xs,ys] = Calibration.aux.ang2xySF(undistFunc(framesSpherical.rpt(:,2),regs.FRMW.polyVars),framesSpherical.rpt(:,3),...
    regs,[],1);
figure,
plot(xs,ys,'r*')
hold on
plot(ptsR(:,1),ptsR(:,2),'g*');
(ptsR(:,1))-(xs(~isnan(xs)))


xsim = xs(~isnan(xs));
max(ptsR(:,1)-xsim),min(ptsR(:,1)-xsim)
ysim = ys(~isnan(ys));
max(ptsR(:,2)-ysim),min(ptsR(:,2)-ysim)


rsph = sqrt(sum(vs.^2,2));
rreg = sqrt(sum(vr.^2,2));

max(rreg-rsph(~isnan(rsph))),min(rreg-rsph(~isnan(rsph)))
figure,plot(rreg-rsph(~isnan(rsph)),'*')
figure,imagesc(reshape(rreg,12,21)-reshape(rsph(~isnan(rsph)),12,21))