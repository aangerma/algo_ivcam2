
%%
load('X:\Users\mkiperwa\projection\F9340671\Cal TM2 3.9.2.0\Matlab\mat_files\ROI_Calib_Calc_in.mat')
load('X:\Users\mkiperwa\projection\F9340671\Cal TM2 3.9.2.0\Matlab\mat_files\cal_init_in.mat')
fw = Pipe.loadFirmware('X:\Users\mkiperwa\projection\F9340671\Cal TM2 3.9.2.0\Matlab\AlgoInternal');
regs = fw.get;
load('X:\Users\mkiperwa\projection\F9340671\Cal TM2 3.9.2.0\Matlab\AlgoInternal\tpsUndistModel.mat')
load('X:\Users\mkiperwa\projection\F9340671\rectData.mat')
 
verbose = 1; 
topMarginPix = 100;
bottomMarginPix = 100;
totRange = 4095;
rectY(1) = 0;
rectY(2) = 480;
rectX(3) = 0;%-88;
rectX(4) = 1024;%1139;


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
[angRect] = calcRectInAngleDim(f2AngX,f2AngY,rectX,rectY,[xF,yF],regs,tpsUndistModel,anglesRng,totRange,verbose);
%%
%{
if verbose
    figure(); hold on;
    plot(angRect.HLang.x(1:lmarginix)+anglesRng,angRect.HLang.y(1:lmarginix)+anglesRng);
    plot(angRect.HLang.x(lmarginix:end)+anglesRng,angRect.HLang.y(lmarginix:end)+anglesRng); legend;
    axis ij;
end
%}
vmin = (angRect.VTang.y+(anglesRng - 100))*anglesRng/(anglesRng - 100); 

%%
vmax = (angRect.VBang.y+(anglesRng - 100))*anglesRng/(anglesRng - 100); 
if verbose
    figure(); plot(vmin); hold all; plot(vmax); legend('vmin','vmax'); axis ij;
end
%%
%% write FOV LUT table 
% vmin=zeros(1,4096);vmin(500:2000)=100;vmin(3000:3500)=100;
% vmax=zeros(1,4096);vmax(500:2000)=4090;vmax(3000:3500)=4090;
% vmin(1:1000) = 0;

vminOrig = vmin';
vmaxOrig = vmax';
vmin = fliplr(totRange-vmaxOrig);
vmax = fliplr(totRange-vminOrig);
% vmin = vminOrig;
% vmax = vmaxOrig;

vs =double(vec([round(vmin);round(vmax)]));
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
hw = HWinterface;
hw.runScript(fileName);

%%
function [xPix,yPix] = inverseAngs(angX,angY,regs,tpsUndistModel)
[angX,angY] = Calibration.Undist.applyPolyUndistAndPitchFix(angX,angY,regs);
vNew = Calibration.aux.ang2vec(angX,angY,regs);
vNew = Calibration.Undist.undistByTPSModel( vNew',tpsUndistModel )';% 2D Undist
[ xPix,yPix] = Calibration.aux.vec2xy(vNew, regs);
end


function [angRect] = calcRectInAngleDim(f2AngX,f2AngY,rectX,rectY,pincushPts,regs,tpsUndistModel,anglesRng,totRange,verbose)
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
nPts = 100;
% vertical top
xVals = double(linspace(rectX(3),rectX(4),nPts));
Ymid = rectY(2)/2;
angXMiddleY = f2AngX(xVals',double(ones(numel(xVals),1)*Ymid));
[angYgrid,angXgrid] = ndgrid(linspace(-anglesRng,anglesRng,numel(angXMiddleY)),angXMiddleY); % Creating a grid in the angle domain along the scan lines
[xValsNew,yValsNew] = inverseAngs(angXgrid,angYgrid,regs,tpsUndistModel);
[minVal1,ix1] = min(abs(yValsNew(1:nPts)-rectY(1)));
[minVal2,ix2] = min(abs(yValsNew(end-nPts+1:end)-rectY(1)));
tempX = xValsNew(1:nPts);
minX = tempX(ix1);
tempX = xValsNew(end-nPts+1:end);
maxX = tempX(ix2);

angRect.VTang.x = f2AngX(double(linspace(minX,maxX,totRange+1)'),double(ones(totRange+1,1)*rectY(1)));
angRect.VTang.y = f2AngY(double(linspace(minX,maxX,totRange+1)'),double(ones(totRange+1,1)*rectY(1)));
if verbose
    figure(120784);plot(angRect.VTang.x+anglesRng,angRect.VTang.y+anglesRng);
    [xFnew,yFnew] = inverseAngs(angRect.VTang.x,angRect.VTang.y,regs,tpsUndistModel);
    figure(151285);axis ij;
    scatter(pincushPts(:,1),pincushPts(:,2));grid minor;
    hold on; scatter(xFnew(:),yFnew(:));grid minor;
end

% vertical Bottom
[minVal1,ix1] = min(abs(yValsNew(1:nPts)-rectY(2)));
[minVal2,ix2] = min(abs(yValsNew(end-nPts+1:end)-rectY(2)));
tempX = xValsNew(1:nPts);
minX = tempX(ix1);
tempX = xValsNew(end-nPts+1:end);
maxX = tempX(ix2);
angRect.VBang.x = f2AngX(double(linspace(minX,maxX,totRange+1)'),double(ones(totRange+1,1)*rectY(2)));
angRect.VBang.y = f2AngY(double(linspace(minX,maxX,totRange+1)'),double(ones(totRange+1,1)*rectY(2)));
if verbose
    figure(120784);plot(angRect.VBang.x+anglesRng,angRect.VBang.y+anglesRng);
    legend('H left', 'H right','V top','V Bottom');   title('angy vs angx');  grid minor;
    figure(120784);hold off;
    [xFnew,yFnew] = inverseAngs(angRect.VBang.x,angRect.VBang.y,regs,tpsUndistModel);
    figure(151285);scatter(xFnew(:),yFnew(:));grid minor;hold off;
    figure(151285); axis ij;
    figure(120784); axis ij;
end

end
