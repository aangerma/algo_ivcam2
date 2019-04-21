function [res] = readSphericalSyncPZR(folder, upscale)
if (folder(end) ~= filesep)
    folder = [folder filesep];
end


if ~exist('upscale','var')
    upscale = true;
end

%% read spherical images

files = dir([folder 'MCLOG_I_640x360_*.bin']);
nFiles = length(files);
if (nFiles == 0)
    error('Bin files not found in %s', folder);
end

for i=1:nFiles
    fn = [folder files(i).name];
    img = io.readBin(fn, [640 360], 'type', 'bin8');
    ir{i} = img;
    cimg = img(50:end-50,50:end-50);
    meanVals(i) = mean(cimg(:));
end

%% find PZR image: the one before the intensity drops
meanBin = (meanVals > (max(meanVals)+min(meanVals))/2);
iPZR = find(meanBin == 0,1)-1;
res.ir = ir{iPZR};

%figure; imagesc(res.ir);

%% read mclog

files = dir([folder 'record_*.csv']);
mclog = readPZRs([folder files.name]);

if (upscale)
    t = 1:mclog.t(end);
    mclog.PZR1 = interp1(mclog.t, mclog.PZR1, t, 'spline');
    mclog.PZR2 = interp1(mclog.t, mclog.PZR2, t, 'spline');
    mclog.PZR3 = interp1(mclog.t, mclog.PZR3, t, 'spline');
    mclog.angX = interp1(mclog.t, mclog.angX, t, 'spline');
    mclog.angY = interp1(mclog.t, mclog.angY, t, 'spline');
    mclog.t = t;
end

fOrder = 150;
b = firpm(fOrder,[0 1.5 18 1e3/2]/(1e3/2),[1 1 0 0], [1 20]);
%[be2,ae2] = ellip(2,0.1,11.5,1.0/(1000/2));
%h = fvtool(b, 1, be2,ae2);
%h.Fs = 1e6;
%h.NumberofPoints = 2^20;
%h.FrequencyScale = 'log';

res.mclog = mclog;

%figure; plot(mclog.angX,mclog.angY, '.-');

end

