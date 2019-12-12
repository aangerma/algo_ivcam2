
%%
load('X:\Users\mkiperwa\projection\F9340671\Cal TM2 3.9.2.0\Matlab\mat_files\ROI_Calib_Calc_in.mat')
load('X:\Users\mkiperwa\projection\F9340671\Cal TM2 3.9.2.0\Matlab\mat_files\cal_init_in.mat')
fw = Pipe.loadFirmware('X:\Users\mkiperwa\projection\F9340671\Cal TM2 3.9.2.0\Matlab\AlgoInternal');
[regs,luts] = fw.get;
load('X:\Users\mkiperwa\projection\F9340671\Cal TM2 3.9.2.0\Matlab\AlgoInternal\tpsUndistModel.mat')
load('X:\Users\mkiperwa\projection\F9340671\rectData.mat')
hw = HWinterface;


verbose = 1; 
topMarginPix = 100;
bottomMarginPix = 100;
totRange = 4095;
rectY(1) = -10;
rectY(2) = 485;
rectX(3) = 0;%-88;
rectX(4) = 1034;%1139;


%% X,Y to angle using scatteredInterpolant from ang to x,y (using udist tps model relevant to unit)
anglesRng = 2047;
[angx,angy] = meshgrid(linspace(-anglesRng,anglesRng,100));
[angx1,angy1] = Calibration.Undist.applyPolyUndistAndPitchFix(angx,angy,regs);
v = Calibration.aux.ang2vec(angx1,angy1,regs);
v = Calibration.Undist.undistByTPSModel( v',tpsUndistModel )';% 2D Undist
[xF,yF] = Calibration.aux.vec2xy(v, regs);

if verbose
    figure();scatter(xF(:),yF(:));grid minor;
    hold on;
    plot(double(ones(regs.GNRL.imgVsize,1)*rectX(3)),double((1:regs.GNRL.imgVsize)'),'LineWidth',2);
    plot(double(ones(regs.GNRL.imgVsize,1)*rectX(4)),double((1:regs.GNRL.imgVsize)'),'LineWidth',2);
    plot(double((1:regs.GNRL.imgHsize)'),double(ones(regs.GNRL.imgHsize,1)*rectY(1)),'LineWidth',2);
    plot(double((1:regs.GNRL.imgHsize)'),double(ones(regs.GNRL.imgHsize,1)*rectY(2)),'LineWidth',2);
    axis ij;
end
f2AngX=scatteredInterpolant(double(xF),double(yF),double(angx(:)));
f2AngY=scatteredInterpolant(double(xF),double(yF),double(angy(:)));

%%
dataPath = 'X:\Users\mkiperwa\projection\F9340671\unitSampledData.mat';
[angRect] = calcRectInAngleDim(f2AngX,f2AngY,rectX,rectY,[xF,yF],regs,tpsUndistModel,anglesRng,totRange,hw,dataPath,verbose,luts);
%%
%{
if verbose
    figure(); hold on;
    plot(angRect.HLang.x(1:lMarginix)+anglesRng,angRect.HLang.y(1:lMarginix)+anglesRng);
    plot(angRect.HLang.x(lMarginix:end)+anglesRng,angRect.HLang.y(lMarginix:end)+anglesRng); legend;
    axis ij;
end
%}
dosStrech = 0;
doCopy = 0;

vmin = interp1(angRect.VTang.x,angRect.VTang.y, linspace(min(angRect.VTang.x),max(angRect.VTang.x),totRange+1));

if dosStrech
    numCells2Stretch = 500;
    vmin = interp1(angRect.VTang.x,angRect.VTang.y, linspace(min(angRect.VTang.x),max(angRect.VTang.x),totRange+1+numCells2Stretch));
    vmin = vmin(1:totRange+1);
else
    if doCopy
        numCells2Copy = 500;
        vmin(end-numCells2Copy:end) = vmin(end-numCells2Copy-1);
    end
end

vmin = (vmin +(anglesRng - 100))*anglesRng/(anglesRng - 100); 
%{
%%
%Same as in the original code
[lMargin,buttomLobeAlignedL,buttomLobeAlignedR,mnI] = getSideMargins(angRect,anglesRng,totRange,verbose); 
%{
vmin(1:round(lMargin)-1)=0;
%}
vmin = max(vmin,buttomLobeAlignedR');

leftShift= 113; %123-10 margin 2 modify
vmin=circshift(vmin,-leftShift); 
vmin(round(mnI-leftShift):end)=0;
%}

%%
vmax = interp1(angRect.VBang.x,angRect.VBang.y, linspace(min(angRect.VBang.x),max(angRect.VBang.x),totRange+1));
if dosStrech
    vmax = interp1(angRect.VBang.x,angRect.VBang.y, linspace(min(angRect.VBang.x),max(angRect.VBang.x),totRange+1+numCells2Stretch));
    vmax = vmax(1:totRange+1);
else
    if doCopy
        vmax(end-numCells2Copy:end) = vmax(end-numCells2Copy-1);
    end
end

vmax = (vmax +(anglesRng - 100))*anglesRng/(anglesRng - 100); 
if verbose
    figure(); plot(vmin); hold all; plot(vmax); legend('vmin','vmax'); axis ij;
end
%{
%%
%Same as in the original code%vmax = min(vmax,4096-buttomLobeAligned');
vmax = min(vmax,4096-buttomLobeAlignedR');


vmax(1:round(lMargin))=0;
vmax=circshift(vmax,-leftShift); 
vmax(round(mnI-leftShift):end)=0;

if verbose
    figure(); plot(vmin); hold all; plot(vmax); legend('vmin','vmax');
end
%}
%%
%% write FOV LUT table 
% vmin=zeros(1,4096);vmin(500:2000)=100;vmin(3000:3500)=100;
% vmax=zeros(1,4096);vmax(500:2000)=4090;vmax(3000:3500)=4090;
% vmin(1:1000) = 0;

vminOrig = vmin;
vmaxOrig = vmax;
vmin = fliplr(totRange-vmaxOrig);
vmax = fliplr(totRange-vminOrig);

%%
% Cos table fix:
cosData = load('X:\Users\hila\L515\projectionByRoiLut\scanDirDIFF\anlyzeYloc\dupTable\data.mat');
[Ttot,tableLength] = getTableTotTime(cosData.table,2,4093);
f=1/(2*Ttot);
w=2*pi()*f;
tVec = 0:Ttot-1;
yCos = -totRange*0.5*cos(w*(tVec))+ totRange*0.5;
ixVmin = nan(numel(vmin),1);
ixVmax = nan(numel(vmax),1);
%Find the place of the vmax/vmin values in the correct cosine function
for k = 1:numel(vmin)
    [minVal1,ixVmin(k,1)] = min(abs(vmin(1,k)-yCos));
    [minVal2,ixVmax(k,1)] = min(abs(vmax(1,k)-yCos));
end
% Find their time ratio from the full period 
tVminRatio = tVec(ixVmin)./Ttot;
tVmaxRatio = tVec(ixVmax)./Ttot;
% Normalize each point in time in the table to the full period (i.e. scan)
% time
tableCumSum = cumsum(cosData.table(2:4093));
tableRatios = tableCumSum./Ttot;
% Find the loacation in the table of the n
newTime4vmin=interp1(tableRatios,tableCumSum,tVminRatio);
newTime4vmax=interp1(tableRatios,tableCumSum,tVmaxRatio);
ixVmin = nan(numel(vmin),1);
ixVmax = nan(numel(vmax),1);
for k = 1:numel(vmin)
    [minVal1,ixVmin(k,1)] = min(abs(newTime4vmin(1,k)-tableCumSum));
    [minVal2,ixVmax(k,1)] = min(abs(newTime4vmax(1,k)-tableCumSum));
end
figure; plot(vmin);hold on; plot(vmax);plot(ixVmin);plot(ixVmax);legend('vmin','vmax','New vmin','New vmax');
vmin = ixVmin';
vmax = ixVmax';


% figure; plot(w*(0:Ttot-1),yCos);
% figure; plot(cosData.table(2:4094));
% figure; plot(tVminRatio); hold on; plot(tVmaxRatio);plot(tableRatios);legend('tVminRatio','tVmaxRatio','tableRatios');
%%
vs =double(vec([round(vmin);round(vmax)]));

%%
% [vsTrans] = int32(transformV(vs,totRange,0.9));
% vs8 = reshape(vsTrans,8,[]);
vs8 = reshape(vs,8,[]);

vsh = reshape(vec(dec2hex(bitand(vs8,totRange),3)'),8,[])';
vshFull = repmat('0',4096,8);
vshFull(1:4:end,:) = vsh(3:3:end,:);
vshFull(2:4:end,:) = vsh(2:3:end,:);
vshFull(3:4:end,:) = vsh(1:3:end,:);

%% write script to txt file
fpath='X:\Users\mkiperwa\projection\F9340671\lut'; 
mkdirSafe(fpath); 
fileName='FOVlut.txt'; 
fileID = fopen(fileName,'w');

n=4096; %32
start_add=hex2dec('4000');
% ws=''; 
for i=1:n
    end_add= start_add + 4;
    fprintf(fileID,'mwd 850e%04x 850e%04x %s\n',start_add,end_add,vshFull(i,:));
    start_add=end_add;
end
fclose(fileID);
copyfile(fileName,fullfile(fpath,fileName),'f');

%% write table to bin
writeTableToBin(vshFull, fpath); 
hw.runScript(fileName);

%%
function [xPix,yPix] = inverseAngs(angX,angY,regs,tpsUndistModel,luts)
[xPix,yPix] = ang2imageXy(angX,angY,regs,luts);
% [angX,angY] = Calibration.Undist.applyPolyUndistAndPitchFix(angX,angY,regs);
% vNew = Calibration.aux.ang2vec(angX,angY,regs);
% vNew = Calibration.Undist.undistByTPSModel( vNew',tpsUndistModel )';% 2D Undist
% [ xPix,yPix] = Calibration.aux.vec2xy(vNew, regs);
end


function [angRect] = calcRectInAngleDim(f2AngX,f2AngY,rectX,rectY,pincushPts,regs,tpsUndistModel,anglesRng,totRange,hw,dataPath,verbose,luts)
%{
% Horizontal left
angRect.HLang.x=f2AngX(double(ones(regs.GNRL.imgVsize,1)*rectX(3)),double((1:regs.GNRL.imgVsize)'));
angRect.HLang.y=f2AngY(double(ones(regs.GNRL.imgVsize,1)*rectX(3)),double((1:regs.GNRL.imgVsize)'));

if verbose
    figure(120784);hold on; axis ij; plot(angRect.HLang.x+anglesRng,angRect.HLang.y+anglesRng);
    [xFnew,yFnew] = inverseAngs(angRect.HLang.x,angRect.HLang.y,regs,tpsUndistModel);
    hold on; scatter(xFnew(:),yFnew(:));grid minor;
end
%%

% Horizontal right 
angRect.HRang.x=f2AngX(double(ones(regs.GNRL.imgVsize,1)*rectX(4)),double((1:regs.GNRL.imgVsize)'));
angRect.HRang.y=f2AngY(double(ones(regs.GNRL.imgVsize,1)*rectX(4)),double((1:regs.GNRL.imgVsize)'));

if verbose
    figure(120784);plot(angRect.HRang.x+anglesRng,angRect.HRang.y+anglesRng);
    [xFnew,yFnew] = inverseAngs(angRect.HRang.x,angRect.HRang.y,regs,tpsUndistModel);
    figure(151285);scatter(xFnew(:),yFnew(:));grid minor;
end
%}
nPts = 1000;
% vertical top
%{
nPtsPincush = sqrt(numel(pincushPts(:,1)));
Ymid = (rectY(1) + rectY(2))/2;
[minVal1,ix1] = min(abs(pincushPts(1:nPtsPincush,2)-Ymid));
[minVal2,ix2] = min(abs(pincushPts(end-nPtsPincush+1:end,2)-Ymid));
tempX = pincushPts(1:nPtsPincush,1);
minX = tempX(ix1);
tempX = pincushPts(end-nPtsPincush+1:end,1);
maxX = tempX(ix2);

xVals = double(linspace(minX,maxX,nPts));

angXMiddleY = f2AngX(xVals',double(ones(numel(xVals),1)*Ymid));
%}

[angXsampled,timeVec] = extractAngXfromSampledData(dataPath,hw,anglesRng);
angXMiddleY = interp1(timeVec,angXsampled,linspace(timeVec(1),timeVec(end),nPts));
angYvec = linspace(-anglesRng,anglesRng,numel(angXMiddleY));
[angYgrid,angXgrid] = ndgrid(angYvec,angXMiddleY); % Creating a grid in the angle domain along the scan lines
[xValsNew,yValsNew] = inverseAngs(angXgrid,angYgrid,regs,tpsUndistModel,luts);
xValsNew = reshape(xValsNew,nPts,nPts);
yValsNew = reshape(yValsNew,nPts,nPts);
[minVal1,iy1] = min(abs(yValsNew-rectY(1)));


angRect.VTang.x = angXMiddleY;
angRect.VTang.y = angYvec(iy1);
if verbose
    figure(120784);plot(angRect.VTang.x+anglesRng,angRect.VTang.y+anglesRng);
    [xFnew,yFnew] = inverseAngs(angRect.VTang.x,angRect.VTang.y,regs,tpsUndistModel,luts);
    figure(151285);axis ij;
    scatter(pincushPts(:,1),pincushPts(:,2));grid minor;
    hold on; scatter(xFnew(:),yFnew(:));grid minor;
end

% vertical Bottom
[minVal2,iy2] = min(abs(yValsNew-rectY(2)));

angRect.VBang.x = angXMiddleY;
angRect.VBang.y = angYvec(iy2);
if verbose
    figure(120784);plot(angRect.VBang.x+anglesRng,angRect.VBang.y+anglesRng);
   
    figure(120784);hold off;
    [xFnew,yFnew] = inverseAngs(angRect.VBang.x,angRect.VBang.y,regs,tpsUndistModel,luts);
    figure(151285);scatter(xFnew(:),yFnew(:));grid minor;hold off;
    figure(151285); axis ij;
    figure(120784); axis ij;
end

% Horizontal left
angRect.HLang.x=f2AngX(double(ones(regs.GNRL.imgVsize,1)*rectX(3)),double((1:regs.GNRL.imgVsize)'));
angRect.HLang.y=f2AngY(double(ones(regs.GNRL.imgVsize,1)*rectX(3)),double((1:regs.GNRL.imgVsize)'));

% Horizontal right 
angRect.HRang.x=f2AngX(double(ones(regs.GNRL.imgVsize,1)*rectX(4)),double((1:regs.GNRL.imgVsize)'));
angRect.HRang.y=f2AngY(double(ones(regs.GNRL.imgVsize,1)*rectX(4)),double((1:regs.GNRL.imgVsize)'));
if verbose
    figure(120784);plot(angRect.HLang.x+anglesRng,angRect.HLang.y+anglesRng); 
    plot(angRect.HRang.x+anglesRng,angRect.HRang.y+anglesRng); 
    legend('V top','V Bottom','H left', 'H right');   title('angy vs angx');  grid minor;
end

end

function [x,y] = ang2imageXy(angX,angY,regs,luts)
ixNan = isnan(angX);
[x_,y_] = Pipe.DIGG.ang2xy(angX,angY,regs,[],[]);
[x,y] = Pipe.DIGG.undist(x_,y_,regs,luts,[],[]);
x = single(x)/2^15;
y = single(y)/2^15;
x(ixNan) = nan;
y(ixNan) = nan;
end

function [angX,timeVec] = extractAngXfromSampledData(dataPath,hw,anglesRng)
sampledData = load(dataPath);

[startMirrorAng, locs1] = findpeaks(-sampledData.mirrorAng);
[endMirrorAng, locs2] = findpeaks(sampledData.mirrorAng);
ix = [locs1(1) locs2(1)];
scanPts = sampledData.mirrorAng(ix(1):ix(2));

%{
dsmXscaleStr = hw.cmd('mrd fffe3844 fffe3848');
dsmXscaleStr = strsplit(dsmXscaleStr,' ');
dsmXscale = hex2single(dsmXscaleStr{end});
dsmXoffsetStr = hw.cmd('mrd fffe3840 fffe3844');
dsmXoffsetStr = strsplit(dsmXoffsetStr,' ');
dsmXoffset = hex2single(dsmXoffsetStr{end});
%}
dsmXoffset = -scanPts(1);
dsmXscale = 2*anglesRng/(scanPts(end)+ dsmXoffset);
angX = (scanPts + dsmXoffset)*dsmXscale - anglesRng;
timeVec = sampledData.timeVec(ix(1):ix(2));
% figure;plot(timeVec,angX);

end

function [lMargin,buttomLobeAlignedL,buttomLobeAlignedR,mnI] = getSideMargins(angRect,anglesRng,totRange,verbose)
%left lobe
[lMargin, lMarginIx]=min(angRect.HLang.x+2047);
if verbose
    figure(); hold on;
    plot(angRect.HLang.x(1:lMarginIx)+anglesRng,angRect.HLang.y(1:lMarginIx)+anglesRng);
    plot(angRect.HLang.x(lMarginIx:end)+anglesRng,angRect.HLang.y(lMarginIx:end)+anglesRng); legend;
end
buttomLobex=angRect.HLang.x(1:lMarginIx)+anglesRng; 
buttomLobey=angRect.HLang.y(1:lMarginIx)+anglesRng;
buttomLobeAlignedL = accumarray( round(buttomLobex),buttomLobey,[totRange+1 1],@mean);
buttomLobeAlignedL(buttomLobeAlignedL==0) = nan;
mxI = maxind(buttomLobeAlignedL);
mnI = minind(buttomLobeAlignedL);
buttomLobeAlignedL(mxI+1:mnI-1) = smooth1D_(mxI+1:mnI-1,buttomLobeAlignedL(mxI+1:mnI-1),5);
buttomLobeAlignedL(isnan(buttomLobeAlignedL)) = 0;

%% right lobe
[rmargin, rmarginix]=max(angRect.HRang.x+anglesRng);
offsetShift=max(rmargin-totRange+1,0)+20; % 220-113 margin to modify
buttomLobex=angRect.HRang.x(1:rmarginix)+anglesRng-offsetShift; 
buttomLobey=angRect.HRang.y(1:rmarginix)+anglesRng;
if verbose
    figure(); plot(buttomLobex,buttomLobey);
end
buttomLobeAlignedR = accumarray( round(buttomLobex),buttomLobey,[totRange+1 1],@mean);
buttomLobeAlignedR(buttomLobeAlignedR==0) = nan;
mnI = maxind(buttomLobeAlignedR);
mxI = minind(buttomLobeAlignedR);
buttomLobeAlignedR(mxI:mnI-1) = smooth1D_(mxI:mnI-1,buttomLobeAlignedR(mxI:mnI-1),5);
buttomLobeAlignedR(isnan(buttomLobeAlignedR)) = 0;

end

function yy = smooth1D_(x,y,sig)
    y=y(:);
    if(isempty(x))
        x= (1:length(y))';
    else
        x=x(:);
    end
    n = length(y);
    if(isempty(x))
        x=1:n;
    end
    yy = zeros(n,1);
    for i=1:n;
        ker = exp(-0.5/sig^2*(x-x(i)).^2);
        ker = ker/sum(ker);
        yy(i) = nansum(y(:).*ker(:));
    end
end


function [vNew] = transformV(vIn,totRange,alpha)
vNew = (vIn./totRange)*2-1;
vNew = (atan(alpha*vNew)./atan(alpha*1)+1)/2*totRange;
end