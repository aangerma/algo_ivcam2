%%
% Load unit data:
load('X:\Users\mkiperwa\projection\F9340671\Cal TM2 3.9.2.0\Matlab\mat_files\ROI_Calib_Calc_in.mat')
load('X:\Users\mkiperwa\projection\F9340671\Cal TM2 3.9.2.0\Matlab\mat_files\cal_init_in.mat')
load('X:\Users\mkiperwa\projection\F9340671\Cal TM2 3.9.2.0\Matlab\AlgoInternal\tpsUndistModel.mat')

%%
fw = Pipe.loadFirmware('X:\Users\mkiperwa\projection\F9340671\Cal TM2 3.9.2.0\Matlab\AlgoInternal');
[regs,luts] = fw.get;
hw = HWinterface;
verbose = 1;
topMarginPix = 100;
bottomMarginPix = 100;
totRange = 4095;
anglesRng = 2047;
rectY = [-10,485];
rectX = [0,1034];
xF = []; yF = [];f2AngX = []; f2AngY = [];
%%
if verbose
    [angx,angy] = meshgrid(linspace(-anglesRng,anglesRng,100));
    [angx1,angy1] = Calibration.Undist.applyPolyUndistAndPitchFix(angx,angy,regs);
    v = Calibration.aux.ang2vec(angx1,angy1,regs);
    v = Calibration.Undist.undistByTPSModel( v',tpsUndistModel )';% 2D Undist
    [xF,yF] = Calibration.aux.vec2xy(v, regs);
    f2AngX=scatteredInterpolant(double(xF),double(yF),double(angx(:)));
    f2AngY=scatteredInterpolant(double(xF),double(yF),double(angy(:)));
    
    figure();scatter(xF(:),yF(:));grid minor;
    hold on;
    plot(double(ones(regs.GNRL.imgVsize,1)*rectX(1)),double((1:regs.GNRL.imgVsize)'),'LineWidth',2);
    plot(double(ones(regs.GNRL.imgVsize,1)*rectX(2)),double((1:regs.GNRL.imgVsize)'),'LineWidth',2);
    plot(double((1:regs.GNRL.imgHsize)'),double(ones(regs.GNRL.imgHsize,1)*rectY(1)),'LineWidth',2);
    plot(double((1:regs.GNRL.imgHsize)'),double(ones(regs.GNRL.imgHsize,1)*rectY(2)),'LineWidth',2);
    axis ij;
end
dataPath = 'X:\Users\mkiperwa\projection\F9340671\unitSampledData.mat';
[angRect] = calcRectInAngleDim(f2AngX,f2AngY,rectX,rectY,[xF,yF],regs,tpsUndistModel,anglesRng,totRange,hw,dataPath,verbose,luts);

vmin = interp1(angRect.VTang.x,angRect.VTang.y, linspace(min(angRect.VTang.x),max(angRect.VTang.x),totRange+1));
% Take into consideration the matgins where we do not project
vmin = (vmin +(anglesRng - topMarginPix))*anglesRng/(anglesRng - topMarginPix); 

vmax = interp1(angRect.VBang.x,angRect.VBang.y, linspace(min(angRect.VBang.x),max(angRect.VBang.x),totRange+1));
% Take into consideration the matgins where we do not project
vmax = (vmax +(anglesRng - bottomMarginPix))*anglesRng/(anglesRng - bottomMarginPix); 
%%
% Fix orientation bug:
vminOrig = vmin;
vmaxOrig = vmax;
vmin = fliplr(totRange-vmaxOrig);
vmax = fliplr(totRange-vminOrig);
%%
% Fix sine table bug:
[vmin,vmax] = fixV2BugInSineTable(vmin,vmax,totRange);
%% write FOV LUT table 

vs =double(vec([round(vmin);round(vmax)]));
vs8 = reshape(vs,8,[]);

vsh = reshape(vec(dec2hex(bitand(vs8,totRange),3)'),8,[])';
vshFull = repmat('0',totRange+1,8);
vshFull(1:4:end,:) = vsh(3:3:end,:);
vshFull(2:4:end,:) = vsh(2:3:end,:);
vshFull(3:4:end,:) = vsh(1:3:end,:);

%% write script to txt file
fpath='X:\Users\mkiperwa\projection\F9340671\lut'; 
mkdirSafe(fpath); 
fileName='FOVlut.txt'; 
fileID = fopen(fileName,'w');

n=totRange+1; %32
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
% Functions:

function [angRect] = calcRectInAngleDim(f2AngX,f2AngY,rectX,rectY,pincushPts,regs,tpsUndistModel,anglesRng,totRange,hw,dataPath,verbose,luts)
nPts = 1000;
% Get x angles sampled from unit in the middle (y axis) of a scanline
[angXsampled,timeVec] = extractAngXfromSampledData(dataPath,hw,anglesRng);
angXMiddleY = interp1(timeVec,angXsampled,linspace(timeVec(1),timeVec(end),nPts));
angYvec = linspace(-anglesRng,anglesRng,numel(angXMiddleY));
[angYgrid,angXgrid] = ndgrid(angYvec,angXMiddleY); % Creating a grid in the angle domain along the scan lines
[~,yValsNew] = inverseAngs(angXgrid,angYgrid,regs,tpsUndistModel,luts);
yValsNew = reshape(yValsNew,nPts,nPts);
% Find y valuse that are closest to the required minimum y value, i.e.
% rectY(1)
[~,iy1] = min(abs(yValsNew-rectY(1)));


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
% Find y valuse that are closest to the required maximum y value, i.e.
% rectY(2)
[~,iy2] = min(abs(yValsNew-rectY(2)));

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

%{
% Horizontal left
angRect.HLang.x=f2AngX(double(ones(regs.GNRL.imgVsize,1)*rectX(1)),double((1:regs.GNRL.imgVsize)'));
angRect.HLang.y=f2AngY(double(ones(regs.GNRL.imgVsize,1)*rectX(1)),double((1:regs.GNRL.imgVsize)'));

% Horizontal right
angRect.HRang.x=f2AngX(double(ones(regs.GNRL.imgVsize,1)*rectX(2)),double((1:regs.GNRL.imgVsize)'));
angRect.HRang.y=f2AngY(double(ones(regs.GNRL.imgVsize,1)*rectX(2)),double((1:regs.GNRL.imgVsize)'));
if verbose
    figure(120784);plot(angRect.HLang.x+anglesRng,angRect.HLang.y+anglesRng);
    plot(angRect.HRang.x+anglesRng,angRect.HRang.y+anglesRng);
    legend('V top','V Bottom','H left', 'H right');   title('angy vs angx');  grid minor;
end
%}
end


function [angX,timeVec] = extractAngXfromSampledData(dataPath,hw,anglesRng)
sampledData = load(dataPath);
% Calculating angle x data from the output we get into the DSM per current
% unit, sampled using: Z:\Omri\forVladik\AsyncLogger\forMaya.m and also
% backup here: X:\Users\mkiperwa\projection\sampleFromControl
[~, locs1] = findpeaks(-sampledData.mirrorAng); % Get one scan
[~, locs2] = findpeaks(sampledData.mirrorAng);
ix = [locs1(1) locs2(1)];
scanPts = sampledData.mirrorAng(ix(1):ix(2));
%{
% If we want to sample per unit:
dsmXscaleStr = hw.cmd('mrd fffe3844 fffe3848');
dsmXscaleStr = strsplit(dsmXscaleStr,' ');
dsmXscale = hex2single(dsmXscaleStr{end});
dsmXoffsetStr = hw.cmd('mrd fffe3840 fffe3844');
dsmXoffsetStr = strsplit(dsmXoffsetStr,' ');
dsmXoffset = hex2single(dsmXoffsetStr{end});
%}
dsmXoffset = -scanPts(1);
dsmXscale = 2*anglesRng/(scanPts(end)+ dsmXoffset);
% Transfor from DSM anples to algo angle in [-2047,2047] range
angX = (scanPts + dsmXoffset)*dsmXscale - anglesRng;
timeVec = sampledData.timeVec(ix(1):ix(2));
% figure;plot(timeVec,angX);
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

function [xPix,yPix] = inverseAngs(angX,angY,regs,tpsUndistModel,luts)
[xPix,yPix] = ang2imageXy(angX,angY,regs,luts);
% [angX,angY] = Calibration.Undist.applyPolyUndistAndPitchFix(angX,angY,regs);
% vNew = Calibration.aux.ang2vec(angX,angY,regs);
% vNew = Calibration.Undist.undistByTPSModel( vNew',tpsUndistModel )';% 2D Undist
% [ xPix,yPix] = Calibration.aux.vec2xy(vNew, regs);
end

function [vmin,vmax] = fixV2BugInSineTable(vmin,vmax,totRange)
%%
% Cos table fix:
cosData = load('X:\Users\hila\L515\projectionByRoiLut\scanDirDIFF\anlyzeYloc\dupTable\data.mat');
[Ttot,~] = getTableTotTime(cosData.table,2,4093);
f=1/(2*Ttot);
w=2*pi()*f;
tVec = 0:Ttot-1;
yCos = -totRange*0.5*cos(w*(tVec))+ totRange*0.5;
ixVmin = nan(numel(vmin),1);
ixVmax = nan(numel(vmax),1);
%Find the place of the vmax/vmin values in the correct cosine function
for k = 1:numel(vmin)
    [~,ixVmin(k,1)] = min(abs(vmin(1,k)-yCos));
    [~,ixVmax(k,1)] = min(abs(vmax(1,k)-yCos));
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
    [~,ixVmin(k,1)] = min(abs(newTime4vmin(1,k)-tableCumSum));
    [~,ixVmax(k,1)] = min(abs(newTime4vmax(1,k)-tableCumSum));
end
figure; plot(vmin);hold on; plot(vmax);plot(ixVmin);plot(ixVmax);legend('vmin','vmax','New vmin','New vmax');
vmin = ixVmin';
vmax = ixVmax';
end