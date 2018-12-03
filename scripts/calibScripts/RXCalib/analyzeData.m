% Load the data

initDir = '\\tmund-MOBL1.ger.corp.intel.com\C$\git\ivcam2.0\scripts\calibScripts\RXCalib\initConfigCalib';
fw = Pipe.loadFirmware(initDir);
[regs,luts] = fw.get();

load('\\tmund-MOBL1.ger.corp.intel.com\C$\git\ivcam2.0\scripts\calibScripts\RXCalib\collectedDataAvg300\darr.mat');
darr = darr40;

% Get the valid pixels from all captures. A Valid pixel is such that
% whitout changing any thing - it's two recordings of averaged 300 frames
% doesn't differ by more than 1mm in depth and 32 in IR.
IRth = 32;
zth = 1;


dstr = darr(1:end,1);
valid = ones(size(dstr(1).z));
for i = 1:numel(dstr)
   dstr(i).valid =  (abs(darr(i,1).z/8-darr(i,2).z/8)<=zth).*(abs(darr(i,1).i-darr(i,2).i)<=IRth);
   valid = valid .* dstr(i).valid;
end
tabplot;imagesc(valid);
title('Valid Pixels Across All Recordings');

%% Get for each pixel his IR values and depth
valid = logical(valid);
nPixels = sum(valid(:));
nCaptures = numel(dstr);
pIR = zeros(nPixels,2*nCaptures);
pDepth = zeros(nPixels,2*nCaptures);
for i = 1:nCaptures
    pIR(:,i*2-1:i*2) = [darr(i,1).i(valid),darr(i,2).i(valid)];
    pDepth(:,i*2-1:i*2) = [darr(i,1).z(valid)/8, darr(i,2).z(valid)/8];
end
plot(pIR(43050,:),pDepth(43050,:),'o')




% % Analyze the center quarter of the image:
% sz = size(darr(1).i);
% centerSize = sz/4;
% zStream = zeros([100,100,numel(darr)]);
% iStream = zeros([100,100,numel(darr)]);
% for i = 1:numel(darr)
% %     iStream(:,:,i) = darr(i).i(sz(1)/2-centerSize(1)/2+1:sz(1)/2+centerSize(1)/2,sz(2)/2-centerSize(2)/2+1:sz(2)/2+centerSize(2)/2);
% %     zStream(:,:,i) = darr(i).z(sz(1)/2-centerSize(1)/2+1:sz(1)/2+centerSize(1)/2,sz(2)/2-centerSize(2)/2+1:sz(2)/2+centerSize(2)/2);
%     iStream(:,:,i) = darr(i).i(117:216,56:155);
%     zStream(:,:,i) = darr(i).z(117:216,56:155);
% 
% end
% zStream = zStream/8;
% % get rtd from r
% rtdStream = 2*zStream+regs.DEST.txFRQpd(1);
%     
% plot(squeeze(iStream(50,50,:)),squeeze(rtdStream(50,50,:)),'o')
% 


%% 
% base = '\\tmund-MOBL1.ger.corp.intel.com\C$\git\ivcam2.0\scripts\calibScripts\RXCalib\collectedData';
% ir = zeros(20,480,640);
% z = zeros(20,480,640);
% for i = 0:19
%    iname = strcat('frame_',sprintf('%03d',i),'_ir.bini'); 
%    zname = strcat('frame_',sprintf('%03d',i),'_d.binz'); 
%    ir(i+1,:,:) = io.readBin(fullfile(base,iname));
%    z(i+1,:,:) = io.readBin(fullfile(base,zname));
%    tabplot; imagesc(squeeze(ir(i+1,:,:)));
% end
% 
% plot(ir(:,250,250),z(:,250,250),'o')




