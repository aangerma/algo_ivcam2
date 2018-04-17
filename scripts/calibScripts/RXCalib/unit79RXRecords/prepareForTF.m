clear

[filepath,~,~] = fileparts(mfilename('fullpath'));
files = dir(filepath);
j = 1;
for i = 1:numel(files)
    if length(files(i).name) < 5
        continue;
    end
    if all(files(i).name(end-3:end) == '.mat')
        data = load(fullfile(filepath,files(i).name));
        darr(j,:,:) = data.darr;
        j = j +1;
    end
end


%% Show the images
[nDist,nIllum,~] = size(darr);
tabplot;
subplot(nDist,nIllum,1)
for i = 1:nDist
    for j = 1:nIllum
        subplot(nDist,nIllum,(i-1)*nIllum + j)
        imagesc(darr(i,j,1).i);
    end
end

tabplot;
subplot(nDist,nIllum,1)
for i = 1:nDist
    for j = 1:nIllum
        subplot(nDist,nIllum,(i-1)*nIllum + j)
        imagesc(darr(i,j,1).z);
    end
end

roi = zeros(size(darr(1,1,1).z,1),size(darr(1,1,1).z,2),nDist);
for i = 1:nDist
    I = darr(i,1,1).i;
    roi(:,:,i) = roipoly(normByMax(I));
end
% Get the valid pixels from all captures. A Valid pixel is such that
% whitout changing any thing - it's two recordings of averaged 300 frames
% doesn't differ by more than 1mm in depth and 32 in IR.
IRth = 32;
zth = 1;
tabplot;
subplot(nDist,nIllum,1)
for j = 1:nDist
    for i = 1:nIllum
        d = darr(j,i,1);
        d.valid =  (abs(darr(j,i,1).z/8-darr(j,i,2).z/8)<=zth).*(abs(darr(j,i,1).i-darr(j,i,2).i)<=IRth).*roi(:,:,j);
        dstr(j,i) = d;
        subplot(nDist,nIllum,(j-1)*nIllum + i)
        imagesc(d.valid);
        
    end
end
savePath = 'X:\Data\IvCam2\RXCalib\training\forTF\darrUnit79_4dists.mat';
[pIR,pDepth] = darr2pixels(dstr(1:4,:),savePath);
savePath = 'X:\Data\IvCam2\RXCalib\training\forTF\darrUnit79_2dists_CB.mat';
[~,~] = darr2pixels(dstr(5:6,:),savePath);

