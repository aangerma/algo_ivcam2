N = 30;
dirName = '\\tmund-MOBL1.ger.corp.intel.com\C$\git\ivcam2.0\scripts\calibScripts\GammaCalib\PGCaptures';
prefixNeon = 'PGNeonOnly_2018-02-28-145305-';
suffix = '.pgm';
pgNeon = rot90(avgStream(dirName,prefixNeon,suffix,N),2);

[~,ccNeonOrig] = DetectBlackCBPointsAndSortedValues(pgNeon);
[pgNeonCorr,~,~,blackwhiteNeon ] = correctCheckerboard( pgNeon);
[~,ccNeonCorr] = DetectBlackCBPointsAndSortedValues(pgNeonCorr);
ccNeonCorr = [blackwhiteNeon(1) ;ccNeonCorr ;blackwhiteNeon(2) ];

ivIm = imread('\\tmund-MOBL1.ger.corp.intel.com\C$\git\ivcam2.0\scripts\calibScripts\GammaCalib\ivcamSameSpot.pgm');
[~,ccIvcam,pCorners] = DetectBlackCBPointsAndSortedValues(ivIm);
[ivImCorr,~,~,blackwhiteIV ] = correctCheckerboard( ivIm);
[~,ccIvcamCorr] = DetectBlackCBPointsAndSortedValues(ivImCorr,pCorners);
ccIvcamCorr = [blackwhiteIV(1) ;ccIvcamCorr ;blackwhiteIV(2) ];


subplot(1,2,1)
plot([ccNeonOrig,ccIvcam],'-o'),title('Intensity per black square - Original')
legend({'PG with Neon','Ivcam'},'location','northwest');
subplot(1,2,2)
plot([ccNeonCorr,ccIvcamCorr],'-o'),title('Intensity per black square - Corrected')
legend({'PG with Neon','Ivcam'},'location','northwest');

plot(ccIvcamCorr,ccNeonCorr,'-o'), xlabel('Corrected IVCAM IR values'), ylabel('Desired IVCAM IR values'), title('IR Transformation Map')


maxIR = 2^12-1;
minVal = 0.05*maxIR;
maxVal = 0.95*maxIR;

ccNeonCorrInit = ccNeonCorr*maxIR/255;
ccIvcamCorrInit = ccIvcamCorr*maxIR/255;

scale = (maxVal-minVal)/(max(ccNeonCorrInit)-min(ccNeonCorrInit));
offset = minVal - min(scale*ccNeonCorrInit);
ccNeonCorrT = ccNeonCorrInit*scale+offset;


scale = (maxVal-minVal)/(max(ccIvcamCorrInit)-min(ccIvcamCorrInit));
offset = minVal - min(scale*ccIvcamCorrInit);
ccIvcamCorrT = ccIvcamCorrInit*scale+offset;
ccIvcamCorrT = ccIvcamCorrInit;

deg = 5;
p = polyfit(ccIvcamCorrT,ccNeonCorrT,deg);
x1 = linspace(0,1,65)*maxIR;
y1 = max(min(polyval(p,x1),maxIR),0);
figure
plot(ccIvcamCorrT,ccNeonCorrT,'o'), xlabel('Corrected IVCAM IR values'), ylabel('Desired IVCAM IR values'), title('IR Transformation Map')
hold on
plot(x1,y1)
axis([0 maxIR 0 maxIR])


gammaregs.FRMW.diggGammaFactor = single(1.0);
gammaregs.DIGG.gammaScale = int16([1024*scale 1024]);
gammaregs.DIGG.gammaShift = int16([offset 0]);
gammaregs.DIGG.gammaBypass = uint8(0);       
gammaregs.DIGG.gamma = uint16([y1 0 ]);
 
fw.setRegs(gammaregs,'');
fw.get();