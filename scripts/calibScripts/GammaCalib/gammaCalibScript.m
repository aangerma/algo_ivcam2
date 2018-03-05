% Get avg frame
hw = HWinterface();
d = hw.getFrame();
% I = imread('\\tmund-MOBL1.ger.corp.intel.com\C$\git\ivcam2.0\scripts\calibScripts\GammaCalib\ivcamSameSpot.pgm');
I = d.i;

% Find checkerboard corners
[p,bsz] = detectCheckerboardPoints(normByMax(I)); % p - 3 checkerboard points. bsz - checkerboard dimensions.
if (size(p,1)~=9*13)
    B = I; B(I>80) = 255;
    [p,bsz] = detectCheckerboardPoints(normByMax(B)); % p - 3 checkerboard points. bsz - checkerboard dimensions.
    
end
assert(size(p,1)==9*13);

pmat = reshape(p,[bsz-1,2]);

rows = bsz(1)-1; cols = bsz(2)-1;
pPerSq = cat(3,pmat(1:rows-1,1:cols-1,:),...
                 pmat(1:rows-1,(1:cols-1)+1,:),...
                 pmat((1:rows-1)+1,1:cols-1,:),...
                 pmat((1:rows-1)+1,(1:cols-1)+1,:));
squares = reshape(pPerSq,[(rows-1)*(cols-1),8]);
indOneColor = toeplitz(mod(1:max(rows-1,cols-1),2));
indOneColor = indOneColor(1:rows-1,1:cols-1);
oddSquares = squares(logical(indOneColor(:)),:);
evenSquares = squares(logical(1-indOneColor(:)),:);
ccOdd = mean(centerColor(I,oddSquares));
ccEven = mean(centerColor(I,evenSquares));
if ccOdd > ccEven 
    blackSquares=evenSquares;
    whiteSquares=oddSquares;
else
    blackSquares=oddSquares;
    whiteSquares=evenSquares;
end
H = fspecial('disk',4);
If = imfilter(I,H); 
cpBlack = centerPoints(blackSquares);
ccBlack = centerColor(If,blackSquares);

ord = [1,2,3,4,12,20,28,36,44,48,47,46,45,37,29,21,13,5,6,7,8,16,24,32,40,43,42,41,33,25,17,9,10,11,19,27,35,39,38,30,22,14,15,23,31,34,26,18];

% figure
% imagesc(I)
% colormap gray
% hold on; 
% text(cpBlack(ord,1),cpBlack(ord,2),cellfun(@num2str,num2cell(1:size(cpBlack,1)),'un',0),'Color','red','FontWeight','bold');
% title('Calib Target with Internsity Order')
% figure
% plot(ccBlack(ord),'ro')
% title('Intensity per black square')


% Center points and colors for the black squares sorted
cpBlack = cpBlack(ord,:);
ccBlack = ccBlack(ord);

% Get a TPS model that corrects the image
% Identify Checkerboard and mitigates vignneting(only on the CB)
r = 1/8;
whitePoints = [(1-r)*whiteSquares(:,1:2) + (r)*whiteSquares(:,7:8);
                (r)*whiteSquares(:,1:2) + (1-r)*whiteSquares(:,7:8);
                (1-r)*whiteSquares(:,3:4) + (r)*whiteSquares(:,5:6);
                (r)*whiteSquares(:,3:4) + (1-r)*whiteSquares(:,5:6);
                (0.5)*whiteSquares(:,1:2) + (0.5)*whiteSquares(:,7:8)];
                
blackPoints = [(1-r)*blackSquares(:,1:2) + (r)*blackSquares(:,7:8);
                (r)*blackSquares(:,1:2) + (1-r)*blackSquares(:,7:8);
                (1-r)*blackSquares(:,3:4) + (r)*blackSquares(:,5:6);
                (r)*blackSquares(:,3:4) + (1-r)*blackSquares(:,5:6);];
                      
% For each point, get the corresponding value from the image
allPoints = [whitePoints;blackPoints];
% Use 5x5 median filtering to reduce the change we sample a specific point
% which is very noisy.
Imed = medfilt2(I,[5 5]);
trueValues = interp2(1:size(I,2),1:size(I,1),single(Imed),allPoints(:,1),allPoints(:,2));

minVal = max(trueValues(end-size(blackPoints,1)+1:end)); % Max of black squares
maxVal = max(trueValues);                                % Max of white squares

perfectValues = [maxVal*ones(size(whitePoints,1),1);minVal*ones(size(blackPoints,1),1)];
xyv = [allPoints,perfectValues];
targetV = trueValues;

% Get a thin plate spline model for the transformation
tps=TPS(xyv,targetV);

% Apply the transformation on the desired image IR values:
referenceCC = linspace(minVal,maxVal,length(ccBlack)+2)';
source = [cpBlack,referenceCC(2:end-1)];
dest = tps.at(source);

subplot(121)
plot([ccBlack,dest],'-o'),title('Intensity per black square - Corrected')
legend({'Ivcam','IvcamCorrected'},'location','northwest');

subplot(122)
plot(ccBlack,dest,'-o'),xlabel('Corrected IVCAM IR values'), ylabel('Desired IVCAM IR values'), title('IR Transformation Map')
legend({'Ivcam','IvcamCorrected'},'location','northwest');
axis([0 255 0 255])


%%


maxIR = 2^12-1;
minVal = 0.05*maxIR;
maxVal = 0.95*maxIR;

ccTarget = dest*maxIR/255;
ccIvcamInit = ccBlack*maxIR/255;

scale = (maxVal-minVal)/(max(ccTarget)-min(ccTarget));
offset = minVal - min(scale*ccTarget);
ccTargetT = ccTarget*scale+offset;


scale = (maxVal-minVal)/(max(ccIvcamInit)-min(ccIvcamInit));
offset = minVal - min(scale*ccIvcamInit);
ccIvcamT = ccIvcamInit*scale+offset;
% ccIvcamT = ccIvcamInit;

deg = 5;
p = polyfit(ccIvcamT,ccTargetT,deg);
x1 = linspace(0,1,65)*maxIR;
y1 = max(min(polyval(p,x1),maxIR),0);
figure
plot(ccIvcamT,ccTargetT,'o'), xlabel('Corrected IVCAM IR values'), ylabel('Desired IVCAM IR values'), title('IR Transformation Map')
hold on
plot(x1,y1)
axis([0 maxIR 0 maxIR])


%%

ir = 1:maxIR;
ir_out = max(min(polyval(p,ir),maxIR),0);
figure;
plot([ccIvcamT,ccTargetT,ir_out(int32(ccIvcamT))'],'-o'),title('Expected intensity per black square - After correction')
legend({'Ivcam Orig','Ivcam Corrected Target','Expected IVAM after lut'},'location','northwest');

gammaregs.FRMW.diggGammaFactor = single(1.0);
gammaregs.DIGG.gammaScale = int16([1024*scale 1024]);
gammaregs.DIGG.gammaShift = int16([offset 0]);
gammaregs.DIGG.gammaBypass = uint8(0);       
gammaregs.DIGG.gamma = uint16([y1 0 ]);
fw = Firmware;
fw.setRegs(gammaregs,'newGammeBW.txt');
fw.get();
fw.genMWDcmd('DIGG.*gamma','newGammeBW.txt');


%%
scale = 1;
offset = 0;

gammaregs.FRMW.diggGammaFactor = single(1.0);
gammaregs.DIGG.gammaScale = int16([1024*scale 1024]);
gammaregs.DIGG.gammaShift = int16([offset 0]);
gammaregs.DIGG.gammaBypass = uint8(0);       
gammaregs.DIGG.gamma = uint16([linspace(0,4095,65) 0 ]);
fw = Firmware;
fw.setRegs(gammaregs,'defaultBW.txt');
fw.get();
fw.genMWDcmd('DIGG.*gamma','defaultBW.txt');