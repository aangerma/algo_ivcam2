%% read spherical images
sphericalCaptureDir = 'D:\Data\Ivcam2\PZR\FW_IVCAM2_1_2_5_1_LOS\Capture_Spherical_0319_03\';
files = dir([sphericalCaptureDir 'MCLOG_I_640x360_*.bin']);
for i=1:length(files)
    fn = [sphericalCaptureDir files(i).name];
    ir{i} = io.readBin(fn, [640 360], 'type', 'bin8');
end

sz = size(ir{1});
IR = zeros([length(files) flip(sz)], 'uint8');
for i=1:length(files)
    %IR(i,:,:) = rot90(shrinkScanlinesX(fliplr(ir{i})));
    IR(i,:,:) = rot90(fliplr(ir{i}));
end

% for Capture_Spherical_0319_01
%iSphericalCapture = 61; % found manually using Utils.displayVolumeSliceGUI(IR)

% for Capture_Spherical_0319_02
%iSphericalCapture = 56; % found manually using Utils.displayVolumeSliceGUI(IR)

% for Capture_Spherical_0319_03
iSphericalCapture = 67; % found manually using Utils.displayVolumeSliceGUI(IR)


irSpherical = ir{iSphericalCapture};
figure; imagesc(irSpherical);

%% read mclog
mclog = readPZRs([sphericalCaptureDir 'record_PZR.csv']);
figure; plot(mclog.angX,mclog.angY, '.-');


