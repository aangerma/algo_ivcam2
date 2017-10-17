function [newdata, I] = doubleFPSScan(varargin)
inFileName = varargin{1};
inFileName(inFileName == '"') = [];
if nargin > 1
    outFileName = varargin{2};
    outFileName(outFileName == '"') = [];
else
    [pathstr,name,ext] = fileparts(inFileName);
    outFileName = fullfile(pathstr,[name '_60fps' ext]);
end
if nargin > 2
    plotResults = true;
else
    plotResults = false;
end

if ~exist(inFileName,'file')
    error(['no such file: ' inFileName ' exist!!!']);
end

indata = io.readIVS(inFileName);
xy = indata.xy;
y = double(xy(2,:));
[~, maxLocs] = findpeaks(y);

I = 1:maxLocs(1);
c = {1:maxLocs(1)};
for i = 2:2:length(maxLocs)-1
    I = [I maxLocs(i):maxLocs(i+1)];
end

fast = reshape(indata.fast,64,length(indata.fast)/64);
fast = vec(fast(:,I));

newdata.fast = fast;
newdata.xy = xy(:,I);
newdata.slow = indata.slow(I);
newdata.flags = indata.flags(I);

if plotResults
    figure(2342134)
    sp1 = subplot(311); plot(xy(1,:),xy(2,:),newdata.xy(1,:),newdata.xy(2,:),'r');title('scans pos')
    sp2 = subplot(312); plot(xy(1,:),xy(2,:)); title('original scan')
    sp3 = subplot(313); plot(newdata.xy(1,:),newdata.xy(2,:),'r'); title('new scan')
    linkaxes([sp1 sp2 sp3]);
    
    figure(2342135)
    sp4 = subplot(211);
    plot(xy(1,:));hold on; plot(newdata.xy(1,:),'r'); hold off;
    title('x scans')
    
    sp5 = subplot(212);
    plot(xy(2,:));hold on; plot(newdata.xy(2,:),'r'); hold off;
    title('y scans')
    linkaxes([sp4 sp5]);
end
res = io.writeIVS( outFileName,newdata);
if res == -1
    newdata = -1;
    I = -1;
end