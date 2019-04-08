%T = readtable('C:\Program Files (x86)\IVCAM.2.0.Tool\HWMonitorServer\Records\record_12_02_T01.csv');
fPZR_0000 = 'C:\Program Files (x86)\IVCAM.2.0.Tool\HWMonitorServer\Records\offset_0000\record_12_02_56.csv';
fPZR_3000 = 'C:\Program Files (x86)\IVCAM.2.0.Tool\HWMonitorServer\Records\offset_3000\record_12_09_11.csv';
T = readtable(fPZR_0000);
PZR = table2array(T);
PZR = PZR(1:end-1,:);

PZR_W = zeros(5,1); % copy from file

[angX,angY] = calcAngleFromPZRs(PZR(:,9),PZR(:,11),PZR(:,10),PZR_W);
figure; plot(angX,angY,'.-');
hold on; 

PZR_W = zeros(5,1);

%{
A = RegsAlg_Prefilt_PZR_Polarity_PZR1_SA
B = RegsAlg_Prefilt_PZR_Polarity_PZR3_SA
C = RegsAlg_Prefilt_PZR_Polarity_PZR1_PA
D = RegsAlg_Prefilt_PZR_Polarity_PZR3_PA
E = RegsAlg_Prefilt_PZR_Polarity_FA_SF

SA_RAW = A*PZR1 + B*PZR3
PA_RAW = C*PZR1 - D*PZR3
FA_RAW = E*PRZ2

AngX = SA_Sync_Filt = Filt(SA_RAW)
AngY = FA_RW = Filt(PA_RAW) + Filt(FA_RAW)

%}

BA1 = zeros(5,1);
BA2 = zeros(5,1);

fb1 = BA1(1:3)';
fa1 = [1;BA1(4:5)]';
fb2 = BA2(1:3)';
fa2 = [1;BA2(4:5)]';

[be2,ae2] = ellip(2,0.002,10,2/(120000/2));
h = fvtool(fb2, fa2, be2,ae2);

fb2 = 1.0e-08*[  0.274135378286466   0.548270756572933   0.274135378286466];
fa2 = [  1.000000000000000  -1.999851903902470   0.999851914867882];

[be2,ae2] = ellip(2,0.1,15,1.0/(120000/2));
h = fvtool(fb2, fa2, be2,ae2);
h.Fs = 120e6;
h.NumberofPoints = 2^20;
h.FrequencyScale = 'log';

b = firpm(150,[0 1 15 1e3/2]/(1e3/2),[1 1 0 0], [1 20]);
[be2,ae2] = ellip(2,0.1,15,1.0/(1000/2));
h = fvtool(b, 1, be2,ae2);
h.Fs = 1e6;
h.NumberofPoints = 2^20;
h.FrequencyScale = 'log';


PZR_A = 40.8254460518298;
PZR_B = 28.6259521358624;


%ellipti for MC

% read files
sphericalCaptureDir = 'D:\Data\Ivcam2\PZR\FW_IVCAM2_1_2_5_1_LOS\Capture_Spherical_0319_01\';
files = dir([sphericalCaptureDir 'MCLOG_I_640x360_*.bin']);
for i=1:length(files)
    fn = [sphericalCaptureDir files(i).name];
    ir{i} = io.readBin(fn, [640 360], 'type', 'bin8');
end
filesZ = dir('MCLOG_Z_640x360_*.bin');
for i=1:length(filesZ)
    fn = [sphericalCaptureDir filesZ(i).name];
    z{i} = io.readBin(fn, [640 360], 'type', 'bin16');
end

sz = size(ir{1});
IR = zeros([length(files) flip(sz)], 'uint8');
for i=1:length(files)
    %IR(i,:,:) = rot90(shrinkScanlinesX(fliplr(ir{i})));
    IR(i,:,:) = rot90(fliplr(ir{i}));
end

% for Capture_Spherical_0319_01
iSphericalCapture = 61; % found manually using Utils.displayVolumeSliceGUI(IR)


%% set regs
hw.setReg('RASTbiltBypass'     ,true);
hw.setReg('RASTbiltSharpnessR'     ,uint8(0));
hw.setReg('RASTbiltSharpnessS'     ,uint8(0));
hw.setReg('JFILbypass$'         ,false);
hw.setReg('JFILbilt1bypass'    ,true);
hw.setReg('JFILbilt2bypass'    ,true);
hw.setReg('JFILbilt3bypass'    ,true);
hw.setReg('JFILbiltIRbypass'   ,true);
hw.setReg('JFILdnnBypass'      ,true);
hw.setReg('JFILedge1bypassMode',uint8(1));
hw.setReg('JFILedge4bypassMode',uint8(1));
hw.setReg('JFILedge3bypassMode',uint8(1));
hw.setReg('JFILgeomBypass'     ,true);
hw.setReg('JFILgrad1bypass'    ,true);
hw.setReg('JFILgrad2bypass'    ,true);
hw.setReg('JFILirShadingBypass',true);
hw.setReg('JFILinnBypass'      ,true);
hw.setReg('JFILsort1bypassMode',uint8(1));
hw.setReg('JFILsort2bypassMode',uint8(1));
hw.setReg('JFILsort3bypassMode',uint8(1));
hw.setReg('JFILupscalexyBypass',true);
hw.setReg('JFILgammaBypass'    ,false);
hw.setReg('JFILgammaBypass'    ,false);
hw.setReg('JFILinvBypass',true);
hw.shadowUpdate();

%%
hw.setReg('DIGGsphericalEn',true);
hw.shadowUpdate();

%% capture for metrics

delay = 0;
verbose= true;
for i = 1:nFrames
    frames(i) = hw.getFrame();
    if (delay ~= 0)
        pause(delay);
    end
    if (verbose)
        figure(171); imagesc(frames(i).i); title(sprintf('frame %g of %g', i, nFrames));
    end
end

%% set offset

hw.writeAddr('A00E1BA8', uint32(12000)); % Algo JFILspare_007
hw.shadowUpdate();


%% read registers

regs.EXTL.dsmXscale=typecast(hw.read('EXTLdsmXscale'),'single');
regs.EXTL.dsmYscale=typecast(hw.read('EXTLdsmYscale'),'single');
regs.EXTL.dsmXoffset=typecast(hw.read('EXTLdsmXoffset'),'single');
regs.EXTL.dsmYoffset=typecast(hw.read('EXTLdsmYoffset'),'single');

regs.GNRL.zMaxSubMMExp = double(hw.read('GNRLzMaxSubMMExp'));
regs.FRMW.kRaw = hw.read('CBUFspare')';
regs.DEST.depthAsRange = logical(hw.read('depthAsRange'));
regs.DIGG.sphericalOffset = typecast(hw.read('sphericalOffset'), 'int16');
regs.DIGG.sphericalScale = typecast(hw.read('sphericalScale'), 'int16');

regs.DIGG.spare = typecast(hw.read('DIGGspare'),'single');
regs.FRMW.xfov(1) = regs.DIGG.spare(2);
regs.FRMW.yfov(1) = regs.DIGG.spare(3);
regs.FRMW.laserangleH = regs.DIGG.spare(4);
regs.FRMW.laserangleV = regs.DIGG.spare(5);

xfov = regs.FRMW.xfov(1)
yfov = regs.FRMW.yfov(1)

%% capture
hw.setReg('DIGGsphericalEn',false);
hw.shadowUpdate();

frame30 = hw.getFrame(30); figure; imagesc(frame30.i)
[points, gridSize] = Validation.aux.findCheckerboard(frame30.i);
hold on; plot(points(:,1),points(:,2),'+r');
camera.zMaxSubMM = 2^regs.GNRL.zMaxSubMMExp;
camera.K = reshape([typecast(regs.FRMW.kRaw,'single')';1],3,3)';

params = Validation.aux.defaultMetricsParams();
params.camera = camera;
params.target.squareSize = 20;
[score, results] = Validation.metrics.gridInterDist(frame30, params);

v = Validation.aux.pointsToVertices(points, frame30.z, camera);
[wAngX,wAngY] = vertices2worldAngles(v, regs);
figure; plot(wAngX,wAngY, '.-'); title('world angles from the checkeckboard');

[mAngX,mAngY] = vertices2mirrorAngles(v, regs);
figure; plot(mAngX,mAngY, '.-'); title('mirror angles from the checkeckboard');

%% 
%[Y,X]=ndgrid(1:360,1:640);
%FangX = scatteredInterpolant(points(:,1),points(:,2),wAngX);
%FangY = scatteredInterpolant(points(:,1),points(:,2),wAngY);
%angX = FangX(Y,X);
%angY = FangY(Y,X);

% capture one spherical frame
hw.setReg('DIGGsphericalEn',true);
hw.shadowUpdate();
frame = hw.getFrame(); figure; imagesc(frame.i);

irSpherical = ir{iSphericalCapture};
irSpherical = fillHolesMM(irSpherical);

[ptsSph, gridSizeSph] = Validation.aux.findCheckerboard(irSpherical);
figure; imagesc(irSpherical); hold on; plot(ptsSph(:,1),ptsSph(:,2),'+r');

%%
[dsmAngX, dsmAngY] = sphericalXY2dsmAngle(ptsSph(:,1),ptsSph(:,2),regs);
%[mAngX, mAngY] = applyZenithOnAngles(mAngX, mAngY, regs);
figure; plot(dsmAngX, dsmAngY, '.-'); title('mirror angles from the spherical checkeckboard');

%% compare dsm vs real world mirror
figure; plot(mAngX,mAngY, '.-'); title('real world mirror angles vs dsm angles');
hold on; plot(dsmAngX/2, dsmAngY/2, '.-'); 

%%
[Y,X]=ndgrid(1:360,1:640);
FwAngX = scatteredInterpolant(ptsSph(:,1),ptsSph(:,2),wAngX);
FwAngY = scatteredInterpolant(ptsSph(:,1),ptsSph(:,2),wAngY);
FmAngX = scatteredInterpolant(ptsSph(:,1),ptsSph(:,2),mAngX);
FmAngY = scatteredInterpolant(ptsSph(:,1),ptsSph(:,2),mAngY);

WAngX = FwAngX(X,Y); figure; imagesc(WAngX); title 'World angle X in spherical image';
WAngY = FwAngY(X,Y); figure; imagesc(WAngY); title 'World angle Y in spherical image';

%% spherical to XY of IR image
FSph2ImgX = scatteredInterpolant(ptsSph(:,1),ptsSph(:,2),points(:,1));
FSph2ImgY = scatteredInterpolant(ptsSph(:,1),ptsSph(:,2),points(:,2));

%% mclog
%iLog = 8;
%mclog = mcLog(iLog);
mclog = readPZRs([sphericalCaptureDir 'record_PZR.csv']);
figure; plot(mclog.angX,mclog.angY, '.-');
[xSph,ySph] = angle2sphericalXY(mclog.angX,mclog.angY,regs);
figure; imagesc(irSpherical); hold on; plot(xSph,ySph, '.-w');

%% show PZR angles on the real world checker
dsmInX = FSph2ImgX(xSph,ySph);
dsmInY = FSph2ImgY(xSph,ySph);
figure; imagesc(frame30.i); hold on; plot(dsmInX, dsmInY, '.-w');

%% PZR to real world dsm
dsmMAngX = FmAngX(xSph,ySph);
dsmMAngY = FmAngY(xSph,ySph);
figure; plot(dsmMAngX, dsmMAngY, '.-');

%% compare PZR angles to real world mirror angles
figure; plot(dsmMAngX, dsmMAngY, '.-');
hold on; plot(mclog.angX/2,mclog.angY/2, '.-');

figure; plot(dsmMAngX, '.-'); hold on; plot(mclog.angX/2, '.-');
figure; plot(dsmMAngY, '.-'); hold on; plot(mclog.angY/2, '.-');

figure; plot(mclog.angX,mclog.angY, '.-');
mcLogWAngx = interp2(X,Y,WAngX,xSph,ySph);
mcLogWAngy = interp2(X,Y,WAngY,xSph,ySph);
figure; plot(mcLogWAngx, mcLogWAngy, '.-');





