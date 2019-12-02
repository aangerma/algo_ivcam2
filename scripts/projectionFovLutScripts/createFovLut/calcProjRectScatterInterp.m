
%% rectifiedProjection - Creating FOV lut table
% define fov LUT : [vmin, vmax] values for each horizontal location.
% defines projection area.
%%
% load ROI_Calib_Calc_int results of specific unit- get rectX ,rectY of
% projection Boundaries from unit calibration. 
load('X:\Users\hila\L515\projectionByRoiLut\fullTest_release\runTest\roiResultsUnit525.mat')

%%

% load TPS model
load('X:\Users\hila\L515\projectionByRoiLut\F9280525\Algo1 3.09.1\AlgoInternal\tpsUndistModel.mat');

%% X,Y to angle using scatteredInterpolant from ang to x,y (using udist tps model relevant to unit)
maxa=2047;
[angx,angy] = meshgrid(linspace(-maxa,maxa,100));
[angx,angy] = Calibration.Undist.applyPolyUndistAndPitchFix(angx,angy,regs);
v = Calibration.aux.ang2vec(angx,angy,regs);
v = Calibration.Undist.undistByTPSModel( v',tpsUndistModel )';% 2D Undist
[ xF,yF] = Calibration.aux.vec2xy(v, regs);
figure();scatter(xF(:),yF(:));grid minor;

six=scatteredInterpolant(double(xF),double(yF),double(angx(:)));
siy=scatteredInterpolant(double(xF),double(yF),double(angy(:)));

%% addaption to have Full valid fov - should be configuration for all units
n1=round(190);
buffTop =[ones(n1,1)*-8;linspace(-8,-35,1024-n1)';]-8;
n1=280;
n2=185;
buffBottom=[linspace(32,18,n1)';ones(n2,1)*18;linspace(18,28,1024-n1-n2)']+3; 
buffleft=0;
buffright=0;
%%
figure(); hold all; 
% Horizontal left
HLangx=six(double(ones(regs.GNRL.imgVsize,1)*rectX(3)+buffleft),double((1:regs.GNRL.imgVsize)'));
HLangy=siy(double(ones(regs.GNRL.imgVsize,1)*rectX(3)+buffleft),double((1:regs.GNRL.imgVsize)'));
plot(HLangx+2047,HLangy+2047); 

% Horizontal right 
HRangx=six(double(ones(regs.GNRL.imgVsize,1)*rectX(4)-buffright),double((1:regs.GNRL.imgVsize)'));
HRangy=siy(double(ones(regs.GNRL.imgVsize,1)*rectX(4)+buffright),double((1:regs.GNRL.imgVsize)'));
plot(HRangx+2047,HRangy+2047); 

% vertical top
VTangx=six(double((1:regs.GNRL.imgHsize)'),double(ones(regs.GNRL.imgHsize,1)*rectY(1)+buffTop));
VTangy=siy(double((1:regs.GNRL.imgHsize)'),double(ones(regs.GNRL.imgHsize,1)*rectY(1)+buffTop));
plot(VTangx+2047,VTangy+2047);


% vertical Bottom
VBangx=six(double((1:regs.GNRL.imgHsize)'),double(ones(regs.GNRL.imgHsize,1)*rectY(2)+buffBottom));
VBangy=siy(double((1:regs.GNRL.imgHsize)'),double(ones(regs.GNRL.imgHsize,1)*rectY(2)+buffBottom));
plot(VBangx+2047,VBangy+2047); 

legend('H left', 'H right','V top','V Bottom');   title('angy vs angx');  grid minor;  
hold off; 

%% before ears cliping
% vmin=VTangy+2047; 
% upsample = @(x,n)(vec(repmat(x(:),1,4)'));
% vmin = upsample((vmin))';
% % lmargin=min(HLangx+2047); 
% % rmargin=max(HRangx+2047);
% rmargin=4096-220;%220 
% lmargin = 10;%10;
% vmin(1:round(lmargin))=0; 
% vmin(round(rmargin):end)=0; 
% 
% vmax=VBangy+2047; 
% vmax = upsample((vmax))';
% vmax(1:round(lmargin))=0;
% vmax(round(rmargin):end)=0;
% 
% 
% figure(); plot(vmin); hold all; plot(vmax); legend('vmin','vmax');

%% after ears cliping
%left lobe
[lmargin, lmarginix]=min(HLangx+2047);
figure(); hold on; plot(HLangx(1:lmarginix)+2047,HLangy(1:lmarginix)+2047); plot(HLangx(lmarginix:end)+2047,HLangy(lmarginix:end)+2047); legend; 

buttomLobex=HLangx(1:lmarginix)+2047; 
buttomLobey=HLangy(1:lmarginix)+2047;

vmin=VTangy+2047; 
upsample = @(x,n)(vec(repmat(x(:),1,4)'));
vmin = upsample((vmin))';
buttomLobeAligned = accumarray( round(buttomLobex),buttomLobey,[4096 1],@mean);
buttomLobeAligned(buttomLobeAligned==0) = nan;
mxI = maxind(buttomLobeAligned);
mnI = minind(buttomLobeAligned);
buttomLobeAligned(mxI+1:mnI-1) = smooth1D_(mxI+1:mnI-1,buttomLobeAligned(mxI+1:mnI-1),5);
buttomLobeAligned(isnan(buttomLobeAligned)) = 0;
%vmin = max(vmin,buttomLobeAligned');
vmin(1:round(lmargin)-1)=0;
%% right lobe
[rmargin, rmarginix]=max(HRangx+2047);
offsetShift=max(rmargin-4096,0)+20; % 220-113 margin to modify
buttomLobex=HRangx(1:rmarginix)+2047-offsetShift; 
buttomLobey=HRangy(1:rmarginix)+2047;
figure(); plot(buttomLobex,buttomLobey);

buttomLobeAlignedR = accumarray( round(buttomLobex),buttomLobey,[4096 1],@mean);
buttomLobeAlignedR(buttomLobeAlignedR==0) = nan;
mnI = maxind(buttomLobeAlignedR);
mxI = minind(buttomLobeAlignedR);
buttomLobeAlignedR(mxI:mnI-1) = smooth1D_(mxI:mnI-1,buttomLobeAlignedR(mxI:mnI-1),5);
buttomLobeAlignedR(isnan(buttomLobeAlignedR)) = 0;
vmin = max(vmin,buttomLobeAlignedR');
%%
leftShift=113; %123-10 margin 2 modify
vmin=circshift(vmin,-leftShift); 
vmin(round(mnI-leftShift):end)=0;

vmax=VBangy+2047; 
vmax = upsample((vmax))';
%vmax = min(vmax,4096-buttomLobeAligned');
vmax = min(vmax,4096-buttomLobeAlignedR');


vmax(1:round(lmargin))=0;
vmax=circshift(vmax,-leftShift); 
vmax(round(mnI-leftShift):end)=0;


figure(); plot(vmin); hold all; plot(vmax); legend('vmin','vmax');
%%
%% write FOV LUT table 
vs =double(vec([round(vmin);round(vmax)]));
vs8 = reshape(vs,8,[]);
vsh = reshape(vec(dec2hex(bitand(vs8,4095),3)'),8,[])';
vshFull = repmat('0',4096,8);
vshFull(1:4:end,:) = vsh(3:3:end,:);
vshFull(2:4:end,:) = vsh(2:3:end,:);
vshFull(3:4:end,:) = vsh(1:3:end,:);

%% write script to txt file
fpath='X:\Users\hila\L515\projectionByRoiLut\fullTest_release\FOVlut\fixingEars\removeEarsLuts\clipingEarsRightOnly'; 
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
%%
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