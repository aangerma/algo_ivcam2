
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
buffTop =linspace(0,-35,1024)'-6;%added symetric 5 up
buffBottom=[linspace(25,15,1024/4)';ones(768,1)*15]+11; %5;
buffleft=-70;
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

%%
vmin=VTangy+2047; 
upsample = @(x,n)(vec(repmat(x(:),1,4)'));
vmin = upsample((vmin))';
%lmargin=min(HLangx+2047); 
% rmargin=max(HRangx+2047);
rmargin=4096-220; 
lmargin = 10;
vmin(1:round(lmargin))=0; 
vmin(round(rmargin):end)=0; 

vmax=VBangy+2047; 
vmax = upsample((vmax))';
vmax(1:round(lmargin))=0;
vmax(round(rmargin):end)=0;

% vmax1=4095-vmin; 
% vmin1 = 4095-vmax;
% vmin1(vmin==0) = 0;
% vmax1(vmax==0) = 0
% vmin = vmin1;
% vmax = vmax1;


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
fpath='X:\Users\hila\L515\projectionByRoiLut\fullTest_release\FOVlut\lut_6bottom6top'; 
mkdirSafe(fpath); 
fileName='FovLut.txt'; 
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