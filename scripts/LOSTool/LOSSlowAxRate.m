function minError = LOSSlowAxRate(varargin)
p = inputHandler(varargin{:});

fprintf('reading ivs...\n')
ivs = io.readIVS(p.ivsFilename);
fprintf('search for slow channel delay...\n')
[~, slowChDelay] = Calibration.aux.mSyncerPipe(ivs,[],p.verbose);
fprintf('slow channel delay = %d\n', slowChDelay)
w = p.tubeW;
k = p.slowDelayLim;

xy=double(ivs.xy);
slw=ivs.slow;


%% detect scanlines
Y = bitshift(xy(2,:)-min(xy(2,:)),-1);
dY = diff(Y);
DY = conv(dY, ones(1,1001)/1001, 'same');
scan_dir = (DY > 0);
scan_dir = [scan_dir(1) scan_dir];
scan_changes = abs(diff(double(scan_dir)));
nScans = sum(scan_changes)+1;
scan_yIndices = cumsum(scan_changes) + 1;
scan_yIndices = [scan_yIndices(1) scan_yIndices];

% build new coordinates ys : scanline - y
sy = [Y-min(Y)+1; scan_yIndices];

% build sy IR image
sySize = [max(sy(1,:)) nScans];
syIndices = sub2ind(sySize,sy(1,:),sy(2,:));
minError = inf;

for scd = slowChDelay-k:slowChDelay+k
    ir = circshift(slw, scd);
    syImg = accumarray(syIndices', ir, [prod(sySize) 1], @mean);
    syImg = reshape(syImg, sySize);
    
    % fill a small amount of holes along scanlines
    sypImg = padarray(syImg, [1 0], 'replicate', 'both');
    sypCol = im2col(sypImg, [3 1], 'sliding');
    sypSm = (sypCol(1,:)+sypCol(3,:))/2;
    sypImgSm = reshape(sypSm, size(syImg));
    syImg(syImg == 0) = sypImgSm(syImg == 0);
    
    % % crop to work with the central part only
    % syCropRect = [150 400 800 1200];
    % syImgCrop = imcrop(syImg, syCropRect);
    syImgCrop = syImg;
    
    % image normalization
    h = hist(syImgCrop(:), [0:10:4100]);
    hcs = cumsum(h);
    hcs = hcs / max(hcs);
    irMin = find(hcs > 0.001, 1)*10+1;
    irMax = find(hcs > 0.999, 1)*10+1;
    
    syImgNorm = (syImgCrop - irMin) / (irMax - irMin);
    syImgNorm(syImgNorm < 0) = 0;
    syImgNorm(syImgNorm > 1) = 1;
    
    [imagePoints,boardSize] = detectCheckerboardPoints(syImgNorm);
    
    if isempty(imagePoints)
        error('cant find checker points')
    elseif size(imagePoints,1) < 100
        figure(12358); subplot 121;imagesc(syImgCrop);colormap gray
        plot(imagePoints(:,1),imagePoints(:,2),'*')
        error('cant find enough checker points')
    end
    checkerPoints.x = round(reshape(imagePoints(:,1),boardSize-1));
    checkerPoints.y = round(reshape(imagePoints(:,2),boardSize-1));
    
    if imagePoints(1,1) > imagePoints(end,1)
        checkerPoints.x = checkerPoints.x(end:-1:1,:);
        checkerPoints.y = checkerPoints.y(end:-1:1,:);
    end
    if imagePoints(1,2) > imagePoints(end,2)
        checkerPoints.x = checkerPoints.x(:,end:-1:1);
        checkerPoints.y = checkerPoints.y(:,end:-1:1);
    end
    yBorders = arrayfun(@(j) {[checkerPoints.x(j,1):checkerPoints.x(j,end); round(interp1(checkerPoints.x(j,:),checkerPoints.y(j,:),checkerPoints.x(j,1):checkerPoints.x(j,end)))]},1:size(checkerPoints.x,1));
    hErrors = zeros(length(yBorders),1);
    
    for i = 1:length(yBorders)
        J = yBorders{i}(1,:);
        I = yBorders{i}(2,:);
        for k = -w:w
            v =  arrayfun(@(i) syImgNorm(I(i)+k,J(i)),1:length(I));
            hErrors(i) = hErrors(i) + sum(abs(diff(v)));
        end
    end
    elementNum = sum(arrayfun(@(j) size(yBorders{j},2) - 1, 1:length(yBorders))) * (2*w+1);
    hError = sum(hErrors)/elementNum;
    if hError < minError
        minError = hError;
        minSCD = scd;
    end
end

if p.verbose
    figure(12358); subplot 121;imagesc(syImgCrop);colormap gray
    hold on
    plot(imagePoints(:,1),imagePoints(:,2),'*')
    plot(imagePoints(1,1),imagePoints(1,2),'*')
    plot(imagePoints(end,1),imagePoints(end,2),'*')
    legend('checker points','first point','last point')
    for i = 1:length(yBorders)
        % plot(yBorders{i}(1,:),yBorders{i}(2,:),'m')
        plot(yBorders{i}(1,:),yBorders{i}(2,:) - w,'r')
        plot(yBorders{i}(1,:),yBorders{i}(2,:) + w,'r')
    end
    hold off
    s = round(size(syImgCrop)/3);
    subplot 122; imagesc(syImgCrop(s(1):2*s(1),s(2):2*s(2)))
    txt = {['SlowChannel Delay = ' num2str(minSCD)], ['w = ' num2str(w)], ['Total Error = ' num2str(minError)]};
    annotation('textbox',...
        [0.9 0.9 0.1 0.1],...
        'String',txt,...
        'FontSize',8,...
        'FontName','Arial',...
        'LineStyle','-',...
        'EdgeColor',[0.1 0.1 0.1],...
        'LineWidth',0.5,...
        'BackgroundColor',[0.9  0.9 0.9],...
        'Color',[0.84 0.16 0]);
end

end


function p = inputHandler(ivsFilename,varargin)
%% defs
defs.verbose = 1;
defs.tubeW = 5;
defs.slowDelayLim = 1;
[basedir, subDir] = fileparts(ivsFilename);

defs.calibfn = fullfile(basedir,filesep,'calib.csv');
defs.configfn =fullfile(basedir,filesep,'config.csv');

%% varargin parse
p = inputParser;

isfile = @(x) exist(x,'file');
isflag = @(x) or(isnumeric(x),islogical(x));

addOptional(p,'verbose',defs.verbose,isflag);
addOptional(p,'calibFile',defs.calibfn,isfile);
addOptional(p,'configFile',defs.configfn,isfile);
addOptional(p,'tubeW',defs.tubeW,@isnumeric);
addOptional(p,'slowDelayLim',defs.slowDelayLim,@isnumeric);


parse(p,varargin{:});

p = p.Results;



p.ivsFilename = ivsFilename;
%remove " from filename;
p.ivsFilename(p.ivsFilename=='"')=[];

end
