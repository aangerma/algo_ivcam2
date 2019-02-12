% Get configuration 

fw = Pipe.loadFirmware('C:\temp\unitCalib\F8480012\PC24\AlgoInternal');
[regs,luts] = fw.get();

% % Get Spherical Frame and regular Frame
% hw = HWinterface;
% hw.startStream();
% 
% regs.DEST.depthAsRange=true;regs.DIGG.sphericalEn=true;
% r=Calibration.RegState(hw);
% r.add('JFILinvBypass',true);
% r.add('DESTdepthAsRange',true);
% r.add('DIGGsphericalEn',true);
% r.set();
% pause(0.1);
% framesSpherical = Calibration.aux.CBTools.showImageRequestDialog(hw,1,[0.6 0 0; 0 0.6 0; 0 0 1],'DFZ Validation image');
% 
% 
% 
% i = 1;
% targetInfo = targetInfoGenerator('Iv2A1');
% targetInfo.cornersX = 20;
% targetInfo.cornersY = 28;
% d(i).i = framesSpherical(i).i;
% d(i).c = framesSpherical(i).c;
% d(i).z = framesSpherical(i).z;
% pts = Calibration.aux.CBTools.findCheckerboardFullMatrix(framesSpherical(i).i, 1);
% grid = [size(pts,1),size(pts,2),1];
% d(i).pts = pts;
% d(i).grid = grid;
% d(i).pts3d = create3DCorners(targetInfo)';
% d(i).rpt = Calibration.aux.samplePointsRtd(framesSpherical(i).z,pts,regs);
% 
% [~,dfzResSpherical] = Calibration.aux.calibDFZ(d,regs,calibParams,@sprintf,0,1);
% fprintf('Geometric Error Validation Before Reset regular val eGeom: %2.2g\n',dfzRes.GeometricError);
% %     fprintff('Geometric Error Validation Before Reset regular RMS: %2.2g\n',allRes.rmsError);
% fprintf('Geometric Error Validation Before Reset spherical: %2.2g\n',dfzResSpherical);
% r.reset();

hw = HWinterface;
hw.startStream();
frame = hw.getFrame;

hw.setReg('jfilbypass$',1);
hw.cmd('mwd a0020a6c a0020a70 01000100 // DIGGgammaScale');
hw.shadowUpdate;


Calibration.aux.CBTools.showImageRequestDialog(hw,1,[0.6 0 0; 0 0.6 0; 0 0 1],'DFZ Validation image');
frames = hw.getFrame(60);
r=Calibration.RegState(hw);
r.add('JFILinvBypass',true);
r.add('DESTdepthAsRange',true);
r.add('DIGGsphericalEn',true);
r.set();
pause(1);
framesSpherical = hw.getFrame(60);
r.reset();

% rpt in both modes:
pts = Calibration.aux.CBTools.findCheckerboardFullMatrix(framesSpherical.i, 1);
regs.DEST.depthAsRange=1;regs.DIGG.sphericalEn=1;
rptSpherical = mySamplePointsRtd(framesSpherical.z,pts,regs);
rptSpherical = reshape(rptSpherical,[20,28,3]);
targetInfo = targetInfoGenerator('Iv2A1');
targetInfo.cornersX = 20;
targetInfo.cornersY = 28;
grid = [size(pts,1),size(pts,2),1];
framesSpherical.pts = pts;
framesSpherical.grid = grid;
framesSpherical.pts3d = create3DCorners(targetInfo)';
framesSpherical.rpt = Calibration.aux.samplePointsRtd(framesSpherical.z,pts,regs);
[~,dfzResSpherical] = Calibration.aux.calibDFZ(framesSpherical,regs,calibParams,@sprintf,0,1);


pts = Calibration.aux.CBTools.findCheckerboardFullMatrix(frames.i, 1);
regs.DEST.depthAsRange=0;regs.DIGG.sphericalEn=0;
[rptRegular,frames.r] = mySamplePointsRtd(frames.z,pts,regs);
frames.pts3d = create3DCorners(targetInfo)';
frames.rpt = rptRegular;
rptRegular = reshape(rptRegular,[20,28,3]);
calibParams = xml2structWrapper('calibParams.xml');
params.camera.K = (((reshape([typecast(regs.FRMW.kWorld,'single'),1],3,3)')));
params.camera.zMaxSubMM = 4;
params.target.squareSize = 30;
params.expectedGridSize = [];
frames2.z = rot90(frames.z,2);
frames2.i = rot90(frames.i,2);
frames2.c = rot90(frames.c,2);
grid = [size(pts,1),size(pts,2),1];
frames.pts = pts;
frames.grid = grid;

[dfzResEGeom, allRes,dbg] = Validation.metrics.gridInterDist(frames2, params);
[~,dfzRes] = Calibration.aux.calibDFZ(frames,regs,calibParams,@sprintf,0,1);



figure, imagesc(frames.i)
hold on
plot(pts(:,:,1),pts(:,:,2),'g*')
[x,y] = Pipe.DIGG.ang2xy(frames.rpt(:,2),frames.rpt(:,3),regs,[],[]);
[xt,yt] = Pipe.DIGG.undist(x,y,regs,luts,[],[] );
hold on
plot(xt/2^15,yt/2^15,'r*')

% Show differences:
figure,
for i = 1:3
tabplot
imagesc(rptRegular(:,:,i)-rptSpherical(:,:,i)); colorbar;
end
figure, histogram(rptRegular(:,:,1)-rptSpherical(:,:,1))
figure,imagesc(frames.i),hold on, plot(pts(:,:,1),pts(:,:,2),'r*');


v2d = reshape(dbg.v,[12,21,3]);





fprintf('Geometric Error Validation Before Reset regular val eGeom: %2.2g\n',dfzRes.GeometricError);
%     fprintff('Geometric Error Validation Before Reset regular RMS: %2.2g\n',allRes.rmsError);
fprintf('Geometric Error Validation Before Reset spherical: %2.2g\n',dfzResSpherical);

