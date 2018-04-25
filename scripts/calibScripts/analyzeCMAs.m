%% load frames
load('twoDirsCMA_0418.mat')

%% get code
code = uint8(kron(Codes.propCode(64,1),ones(8,1)));

%%
nFrames = size(frames,1);
maxU = zeros([480 640 nFrames], 'uint32');
maxD = zeros([480 640 nFrames], 'uint32');

for i=1:nFrames
    cma = frames{i,4};
    corr = Utils.correlator(cma, code);
    maxU(:,:,i) = squeeze(max(corr,[],1));
    
    cma = frames{i,5};
    corr = Utils.correlator(cma, code);
    maxD(:,:,i) = squeeze(max(corr,[],1));
end

%% depth frames

zU = zeros([480 640 nFrames]);
zD = zeros([480 640 nFrames]);
irU = zeros([480 640 nFrames]);
irD = zeros([480 640 nFrames]);
irBoth = zeros([480 640 nFrames]);

for i=1:nFrames
    zU(:,:,i) = frames{i,2}.z;
    zD(:,:,i) = frames{i,3}.z;
    irU(:,:,i) = frames{i,2}.i;
    irD(:,:,i) = frames{i,3}.i;
    irBoth(:,:,i) = frames{i,4}.i;
end

