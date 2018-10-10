%% initializations and definitions

%checkers and captures definitions
checkerSize = 30;  %mm
checkerLayout = [9 13];
numCaptures = 3;

[xgt, ygt] = ndgrid(1:checkerLayout(1),1:checkerLayout(2));
cornersWorld = ([ygt(:) xgt(:)]-1).*checkerSize;
cornersWorld = [cornersWorld, zeros(size(cornersWorld,1),1)];

% hw initializations
hw = HWinterface();
hw.getFrame(100);

% bug fix - K is not correctly inverted int the calibration and as a result
% contains non zeros in shear
K = hw.getIntrinsics();
K(K<1) = 0;

results = struct('Frame',[],'Distance',[],'GeomErr',[],'FitErr',[],'ReprojErr',[]);
frames = {};
fig = figure(); clf;

%% capture and analysis loop
currentCapture = 0;
retries = 0;
while currentCapture < numCaptures
    
    if retries >2
        fprintf(2,'can''t find the specified checkeboard (%dx%d)\n',checkerLayout(1),checkerLayout(2));
        break;
    end
    
    % capture checkerboard images and detect the checkerboard
    frame = Calibration.aux.CBTools.showImageRequestDialog(hw,1,diag([.5 .5 1]));
    [p,bsz] = Calibration.aux.CBTools.findCheckerboard(normByMax(double(frame.i)), [9,13]);
    if isequal(bsz,checkerLayout)
        currentCapture = currentCapture+1;
        retries = 0;
    else
        retries = retries+1;
        continue;
    end
    
    % convert z to vertices and calculate the geometric (alex) err
    [verts] = Pipe.z16toVerts(frame.z,hw.getIntrinsics(),bitshift(1,hw.read('zMaxSubMMExp')));
    [yg,xg]=ndgrid(0:size(verts,1)-1,0:size(verts,2)-1);
    it = @(k) interp2(xg,yg,k,p(:,1)-1,p(:,2)-1);
    ptV=[it(verts(:,:,1)) it(verts(:,:,2)) it(verts(:,:,3))];
    ptV = ptV';
    [eGeom,eFit]=Calibration.aux.evalGeometricDistortion(reshape(ptV',[checkerLayout 3]),false,checkerSize);
    
    % solve prespective of the checkers and compare to detected locations
    [ro,to] = DSOcvSolvePnP(double(cornersWorld'),double(p'),double(K),double(zeros(1,5)));
    Ro = DSOcvRodrigues(ro);
    ptK = to+ Ro*cornersWorld';
    reprojRms = sqrt(mean(sum((ptV-ptK).^2)));
    
    % store results
    results(currentCapture).Frame = currentCapture;
    results(currentCapture).Distance = to(3);
    results(currentCapture).GeomErr = eGeom;
    results(currentCapture).FitErr = eFit;
    results(currentCapture).ReprojErr = reprojRms;
    
    
    frames = [frames frame]; %#ok<AGROW>
    
    
    %plot points
    hold on;
    plot3(ptV(1,:),ptV(2,:),ptV(3,:),'ob',ptK(1,:),ptK(2,:),ptK(3,:),'+r')
    hold off;
    axis([-500 500,-500 500,0 1000]);
    axis xy;
    
end

%display results
disp(struct2table(results));

%% clean up
clear hw