%cut strips from ivs of small rose containning checker bord
function [croptIVS] = cropCheckerBordScan(ivs,regs,luts,slowChDelay,guardBand,verbose)
if ~exist('verbose','var')
    verbose = 0;
end
if ~exist('guardBand','var')
    guardBand = 0.2;
end
po = Pipe.hwpipe(ivs,regs,luts,Pipe.setDefaultMemoryLayout(),Logger(),[]);
piducialCenter = round(Calibration.calibTarget.find4fiducials(po.iImg));

MaxXY = max(piducialCenter);
MinxXY = min(piducialCenter);
W = MaxXY(1) - MinxXY(1);
H = MaxXY(2) - MinxXY(2);
checkerX = 135/340;
checkerY = 170/235;
checkerW = 90/340*W;
checkerH = 90/235*H;

x0 = checkerX*W+MinxXY(1);
y0 = checkerY*H+MinxXY(2);
checker = round([x0, y0;
    x0+checkerW, y0;
    x0+checkerW, y0+checkerH;
    x0, y0+checkerH]);
checker(:,1) = checker(:,1)*4;

if verbose
    figure(7654);imagesc(po.iImgRAW); hold on;plot(piducialCenter(:,1),piducialCenter(:,2),'*',checker(:,1)/4,checker(:,2),'*')
    title('Image Plane')
end
xy = double(po.xyPix);
MaxXY = max(checker) + round([checkerW checkerH]*guardBand);
MinXY = min(checker) -  round([checkerW checkerH]*guardBand);

checkerI = false(size(xy,2),1);
checkerI(find(xy(1,:)>MinXY(1),1):find(xy(1,:)<MaxXY(1),1,'last')) = true;
checkerI(or(xy(2,:)<MinXY(2), xy(2,:)>MaxXY(2))) = false;

slowShifted = circshift(ivs.slow, slowChDelay);
croptIVS.slow = slowShifted(checkerI);
croptIVS.xy = ivs.xy(:,checkerI);
croptIVS.flags = ivs.flags(checkerI);

if verbose
    bbox = [MinXY(1),MinXY(2);MaxXY(1),MinXY(2);MaxXY(1),MaxXY(2);MinXY(1),MaxXY(2)];
    figure(7655);plot(xy(1,:),xy(2,:),xy(1,checkerI),xy(2,checkerI),bbox(:,1),bbox(:,2),'*')
    title('scan line')
end
end
