function [gammaregs,gammaError] = runGammaCalib(hw,verbose,outputFolder)
%RUNGAMMACALIB calibrates the DIGG gamme block. It's purpose is to align
%the IR response of different units. 
% It assumes a default gamma configuration (passing as is).
% Figurativly, it creates a reference calibration with the original
% albedos, it transform the colors to the image plane while taking into
% account the illumination falloff and gives us a new color per circle(each
% black square has a different albedo circle in it). It then fit a polinom
% to the transformation (which is not necessiraly bijective), and
% calculates a scale and offset so the resulting IR will cover most of the
% IR valid range.

% Set the default gamma configuration
fnAlgoGammaInitMWD = fullfile(outputFolder,filesep,'gammaInit.txt');
fw = hw.getFirmware();
fw.genMWDcmd('DIGG.*gamma',fnAlgoGammaInitMWD);
hw.runScript(fnAlgoGammaInitMWD);
hw.shadowUpdate();

% Get avg of 30 frame
d = Calibration.aux.readAvgFrame(hw,30);
I = d.i;

% Find checkerboard corners
[p,bsz] = detectCheckerboardPoints(normByMax(I)); % p - 3 checkerboard points. bsz - checkerboard dimensions.
%Maybe there is a problem with the function that detects checkerboard
%points, give it another shot.
if (size(p,1)~=9*13)
    B = I; B(I>80) = 255;
    [p,bsz] = detectCheckerboardPoints(normByMax(B)); % p - 3 checkerboard points. bsz - checkerboard dimensions.
end
assert(size(p,1)==9*13,'Can not detect all checkerboard corners');

[gammaregs,~,~] = gammaCalculation(I,p,bsz,verbose);


%% Write the gamma regs
tmpFW = Firmware;
fnAlgoGammaFinalMWD = fullfile(outputFolder,filesep,'gammaFinal.txt');
tmpFW.setRegs(gammaregs,'');
tmpFW.get();
tmpFW.genMWDcmd('DIGG.*gamma',fnAlgoGammaFinalMWD);
hw.runScript(fnAlgoGammaFinalMWD);
% get new image
d = Calibration.aux.readAvgFrame(hw,30);
Ifixed = d.i;
% Evaluate
[~,ccSource,ccTarget] = gammaCalculation(Ifixed,p,bsz,verbose);
[~,S] = polyfit(ccSource,ccTarget,1);
gammaError = S.normr;

if verbose
    
    figure(190790)
    tabplot;
    subplot(121);
    imagesc(I); title('Original');
    subplot(122);
    imagesc(Ifixed); title('Gamma Corrected');
end


end
function [gammaregs,ccSource,ccTarget] = gammaCalculation(I,p,bsz,verbose)
pmat = reshape(p,[bsz-1,2]);
rows = bsz(1)-1; cols = bsz(2)-1;
% convert each square to a 1x8 vector that has the xy of the 4 corners.
pPerSq = cat(3,pmat(1:rows-1,1:cols-1,:),...
                 pmat(1:rows-1,(1:cols-1)+1,:),...
                 pmat((1:rows-1)+1,1:cols-1,:),...
                 pmat((1:rows-1)+1,(1:cols-1)+1,:));
squares = reshape(pPerSq,[(rows-1)*(cols-1),8]);

% The color of the first square defines the color of the rest. Identify
% if it is black or white.
indOneColor = toeplitz(mod(1:max(rows-1,cols-1),2));
indOneColor = indOneColor(1:rows-1,1:cols-1);
oddSquares = squares(logical(indOneColor(:)),:);
evenSquares = squares(logical(1-indOneColor(:)),:);
ccOdd = mean(centerColor(I,oddSquares));
ccEven = mean(centerColor(I,evenSquares));

% We assume that the left upperboard corner in the image is white, and
% below it is the darkest black square. If not, rotate\flip the image os it
% is.

if ccOdd > ccEven 
    blackSquares=evenSquares;
    whiteSquares=oddSquares;
else
    blackSquares=oddSquares;
    whiteSquares=evenSquares;
    % If we got here, it means the top left square is black, we shall flip
    % the image left right. Also, we shall flip the cordinates of the
    % squares.
    I = fliplr(I);
    whiteSquares(:,1:2:end) = size(I,2) + 1 - whiteSquares(:,1:2:end);
    blackSquares(:,1:2:end) = size(I,2) + 1 - blackSquares(:,1:2:end);
end

% Get the center points and colors of the circles that lies inside the black squares:
H = fspecial('disk',4);
If = imfilter(I,H); 
cpBlack = centerPoints(blackSquares);
ccBlack = centerColor(If,blackSquares);
% Use the predefined order to get the sorted (by albedo) values.
ord = [1,2,3,4,12,20,28,36,44,48,47,46,45,37,29,21,13,5,6,7,8,16,24,32,40,43,42,41,33,25,17,9,10,11,19,27,35,39,38,30,22,14,15,23,31,34,26,18];
cpBlack = cpBlack(ord,:);
ccBlack = ccBlack(ord);
% In case The board is rotated by 180, we should see it by nonsense we see
% at the ccBlack. 
if mean(ccBlack(1:9)) > mean(ccBlack(10:18))
    I = rot90(I,2);
    whiteSquares(:,1:2:end) = size(I,2) + 1 - whiteSquares(:,1:2:end);
    blackSquares(:,1:2:end) = size(I,2) + 1 - blackSquares(:,1:2:end);
    whiteSquares(:,2:2:end) = size(I,1) + 1 - whiteSquares(:,2:2:end);
    blackSquares(:,2:2:end) = size(I,1) + 1 - blackSquares(:,2:2:end);
    cpBlack = centerPoints(blackSquares);
    ccBlack = centerColor(rot90(If,2),blackSquares);
    % Use the predefined order to get the sorted (by albedo) values.
    cpBlack = cpBlack(ord,:);
    ccBlack = ccBlack(ord);
    assert(sum((ccBlack(2:end) - ccBlack(1:end-1))<0) <= 15,'Center circle IR values does not make sense');
end


% Get a TPS model that corrects the image
% Identify Checkerboard and mitigates vignneting(only on the CB)

% Use points that lies outside the circles: 
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
                      
% For each point, get the corresponding value from the image. Use 5x5
% median filtering to reduce the chance we sample a specific point 
% which is very noisy.
allPoints = [whitePoints;blackPoints];

Imed = medfilt2(I,[5 5]);
trueValues = interp2(1:size(I,2),1:size(I,1),single(Imed),allPoints(:,1),allPoints(:,2));

minVal = max(trueValues(end-size(blackPoints,1)+1:end)); % Max of black squares
maxVal = max(trueValues);                                % Max of white squares

perfectValues = [maxVal*ones(size(whitePoints,1),1);minVal*ones(size(blackPoints,1),1)];

% Create a perfect Black white IR value map, transform it such that it will
% fit the values in the captured image.
xyV = [allPoints,perfectValues];
targetV = trueValues;

% Get a thin plate spline model for the transformation
tps=TPS(xyV,targetV);

% Apply the transformation on the desired image IR values:
referenceCC = linspace(minVal,maxVal,length(ccBlack)+2)';
source = [cpBlack,referenceCC(2:end-1)];
dest = tps.at(source);

if verbose
    
    figure(190790)
    tabplot;
    subplot(121)
    plot([ccBlack,dest],'-o'),title('Intensity per black square - Corrected')
    legend({'Ivcam','IvcamCorrected'},'location','northwest');
    axis([0 50 0 50])
    
    subplot(122)
    plot(ccBlack,dest,'-o'),xlabel('Corrected IVCAM IR values'), ylabel('Desired IVCAM IR values'), title('IR Transformation Map')
    legend({'Ivcam','IvcamCorrected'},'location','northwest');
    axis([0 255 0 255])
end

% Translate to the true IR range. Use scale and shift to cover more of the
% valid IR range.
margin = 0.025;
maxIR = 2^12-1;
minIRVal = margin*maxIR;
maxIRVal = (1-margin)*maxIR;

% Scale to 12 bits
ccTarget = dest*maxIR/255;
ccIvcamInit = ccBlack*maxIR/255;

% Find the scale and shift for the source value and target values.

scaleT = (maxIRVal-minIRVal)/(max(ccTarget)-min(ccTarget));
offsetT = minIRVal - min(scaleT*ccTarget);
ccTargetT = ccTarget*scaleT+offsetT;


scale = (maxIRVal-minIRVal)/(max(ccIvcamInit)-min(ccIvcamInit));
offset = minIRVal - min(scale*ccIvcamInit);
ccIvcamT = ccIvcamInit*scale+offset;

% Fit the polinom
deg = 5;% Polinom degree
poly = polyfit(ccIvcamT,ccTargetT,deg);

irIn = linspace(0,1,65)*maxIR;
irOut = max(min(polyval(poly,irIn),maxIR),0);
if verbose
    figure(190790)
    plot(ccIvcamT,ccTargetT,'o'), xlabel('Corrected IVCAM IR values'), ylabel('Desired IVCAM IR values'), title('IR Transformation Map')
    hold on
    plot(irIn,irOut)
    axis([0 maxIR 0 maxIR])
end

gammaregs.FRMW.diggGammaFactor = single(1.0);
gammaregs.DIGG.gammaScale = int16([1024*scale 1024]);
gammaregs.DIGG.gammaShift = int16([offset 0]);
gammaregs.DIGG.gammaBypass = uint8(0);       
gammaregs.DIGG.gamma = uint16([irOut 0 ]);

ccSource = ccIvcamT;
ccTarget = ccTargetT;

end
function cc = centerColor(I,squares)
% returns the center color per square (format of nSquaresx8)
 cP = centerPoints(squares);
 cc = interp2(1:size(I,2),1:size(I,1),single(I),cP(:,1),cP(:,2));
end
function cP = centerPoints(squares)
% returns the center location of each square (format of nSquaresx8)
cP = [mean(squares(:,1:2:end),2),mean(squares(:,2:2:end),2)];
end