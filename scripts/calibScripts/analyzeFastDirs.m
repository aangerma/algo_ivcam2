
%% depth frames
nFrames = size(frames,1);

zU = zeros([480 640 nFrames]);
zD = zeros([480 640 nFrames]);
irU = zeros([480 640 nFrames]);
irD = zeros([480 640 nFrames]);
irBoth = zeros([480 640 nFrames]);

for i=1:nFrames
    zU(:,:,i) = max(frames{i,2}.z, 3600);
    zD(:,:,i) = max(frames{i,3}.z, 3600);
    irU(:,:,i) = frames{i,2}.i;
    irD(:,:,i) = frames{i,3}.i;
    irBoth(:,:,i) = frames{i,4}.i;
end

%% find delay diff in pixels

pxDiffs = zeros(1,nFrames);

for i=1:nFrames
    ir = frames{i,1}.i;
    a1 = frames{i,2}.i;
    a2 = frames{i,3}.i;
    [pxDiffs(i)] = Calibration.aux.findCoarseDelay(ir, a1, a2);
end

figure; plot(pxDiffs, '.-')
