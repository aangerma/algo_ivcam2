
OutputDir = 'C:\temp\testingthingsa';
load("X:\Data\IvCam2\FOVExRecords\F9140579_FE\PC05\calibDFZ_input_slim.mat");
load('X:\Data\IvCam2\FOVExRecords\F9140579_FE\PC05\DFZ_im.mat');
calibParams = xml2structWrapper('C:\source\algo_ivcam2\scripts\IV2calibTool\calibParamsVGA.xml');
calibPassed = 0;
captures = {calibParams.dfz.captures.capture(:).type};
shortRangeImages = strcmp('shortRange',captures);
trainImages = strcmp('train',captures);
testImages = strcmp('test',captures);
width = regs.GNRL.imgHsize;
hight = regs.GNRL.imgVsize;
IR_image = im(1).i;
% find effective image "bounding box"
bwIm = IR_image>0;
bbox = [];
bbox([1,3]) = minmax(find(bwIm(round(size(bwIm,1)/2),:)>0.9));
lcoords = minmax(find(bwIm(:,bbox(1)+10)>0.9)');
mcoords = minmax(find(bwIm(:,round(size(bwIm,2)/2))>0.9)');
rcoords = minmax(find(bwIm(:,bbox(3)-10)>0.9)');
bbox(2) = max([lcoords(1),mcoords(1),rcoords(1)]);
bbox(4) = min([lcoords(2),mcoords(2),rcoords(2)])-bbox(2);
nof_secne = numel(captures);

for i = 1:nof_secne
    cap = calibParams.dfz.captures.capture(i);
    targetInfo = targetInfoGenerator(cap.target);

    d(i).i = im(i).i;
    d(i).z = im(i).z;

    pts = Calibration.aux.CBTools.findCheckerboardFullMatrix(d(i).i, 1);
    grid = [size(pts,1),size(pts,2),1];    
    
    targetInfo.cornersX = grid(1);
    targetInfo.cornersY = grid(2);

    
    d(i).pts = pts;
    d(i).grid = grid;
    d(i).pts3d = create3DCorners(targetInfo)';
    d(i).rpt = Calibration.aux.samplePointsRtd(im(i).z,pts,regs);


    croppedBbox = bbox;
    cropRatioX = 0.2;
    cropRatioY = 0.1;
    croppedBbox(1) = croppedBbox(1) + cropRatioX*croppedBbox(3);
    croppedBbox(3) = (1-2*cropRatioX)*croppedBbox(3);
    croppedBbox(2) = croppedBbox(2) + cropRatioY*croppedBbox(4);
    croppedBbox(4) = (1-2*cropRatioY)*croppedBbox(4);
    croppedBbox = int32(croppedBbox);
    imCropped = zeros(size(im(i).i));
    imCropped(croppedBbox(2):croppedBbox(2)+croppedBbox(4),croppedBbox(1):croppedBbox(1)+croppedBbox(3)) = ...
        im(i).i(croppedBbox(2):croppedBbox(2)+croppedBbox(4),croppedBbox(1):croppedBbox(1)+croppedBbox(3));
    ptsCropped = Calibration.aux.CBTools.findCheckerboardFullMatrix(imCropped, 1);
    gridCropped = [size(ptsCropped,1),size(ptsCropped,2),1];
    gridCropped(end+1) = 1;

    d(i).ptsCropped = ptsCropped;
    d(i).gridCropped = gridCropped;
    d(i).rptCropped = Calibration.aux.samplePointsRtd(im(i).z,ptsCropped,regs);
end
runParams.outputFolder = OutputDir;
Calibration.DFZ.saveDFZInputImage(d,runParams);

regs.FRMW.undistAngHorz=zeros(1,6,'single'); regs.FRMW.undistAngVert=zeros(1,6,'single'); regs.FRMW.fovexRadialK=zeros(1,3,'single'); regs.FRMW.fovexTangentP=zeros(1,2,'single'); regs.FRMW.fovexCenter=zeros(1,2,'single'); regs.FRMW.fovexDistModel=logical(0);
calibParams.dfz.undistHorzRange=[-100;100]*ones(1,6); calibParams.dfz.undistVertRange=[-100;100]*ones(1,6); calibParams.dfz.fovexRadialRange=[-100;100]*ones(1,3); calibParams.dfz.fovexTangentRange=[-100;100]*ones(1,2); calibParams.dfz.fovexCenterRange=[-100;100]*ones(1,2);
%     calibParams.dfz.fovxRange=[65,90]; calibParams.dfz.fovyRange=[50,70];
%     calibParams.dfz.zenithNormW=0;
fprintff=@fprintf;
runParams.outputFolder='X:\Users\tmund\foxExp';
%%%trainImages
[dfzRegs,results.geomErr] = Calibration.aux.calibDFZ(d([1,7,12]),regs,calibParams,fprintff,0,[],[],runParams);

regs.FRMW.polyVars = single(zeros(1,741));
[dfzRegs,results.geomErr] = calibDFZ(d([1,7,12]),regs,calibParams,fprintff,0,[],[],runParams);

