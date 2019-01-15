%% Capture 20 Images First 3 are the same as in calibration. Calibrate on the 3 and plot the eGeom error on all.
hw = HWinterface;
hw.startStream;
calibParams = xml2structWrapper('calibParams.xml');
fprintff = @fprintf;
fw = Pipe.loadFirmware('C:\temp\unitCalib\F8200120\PC23\AlgoInternal');
regs = fw.get();
regs.DEST.depthAsRange=true;regs.DIGG.sphericalEn=true;
r=Calibration.RegState(hw);
r.add('JFILinvBypass',true);
r.add('DESTdepthAsRange',true);
r.add('DIGGsphericalEn',true);
r.set();
        
nCorners = 9*13;
d(1)=Calibration.aux.CBTools.showImageRequestDialog(hw,1,diag([.7 .7 1]));
Calibration.aux.CBTools.checkerboardInfoMessage(d(1),fprintff,nCorners);
d(2)=Calibration.aux.CBTools.showImageRequestDialog(hw,1,diag([.6 .6 1]));
Calibration.aux.CBTools.checkerboardInfoMessage(d(2),fprintff,nCorners);
d(3)=Calibration.aux.CBTools.showImageRequestDialog(hw,1,diag([.5 .5 1]));
Calibration.aux.CBTools.checkerboardInfoMessage(d(3),fprintff,nCorners);
for n = 4:20
    d(n)=Calibration.aux.CBTools.showImageRequestDialog(hw,1,[.01 0 .1;0 .01 0; 0.2 0 1]);
    Calibration.aux.CBTools.checkerboardInfoMessage(d(3),fprintff,nCorners);

end


% dodluts=struct;
[dfzRegs,results.geomErr] = Calibration.aux.calibDFZ(d(1:3),regs,calibParams,fprintff,0);
for n = 1:20
    [~,results.extraImagesGeomErr(n)] = Calibration.aux.calibDFZ(d(n),regs,calibParams,fprintff,0,1);
end
r.reset();

figure,
for n = 1:20
    tabplot;
    imagesc(rot90(d(n).i,2));
    title(sprintf('eGeom=%.2g',results.extraImagesGeomErr(n)));
end
figure,tabplot;plot(results.extraImagesGeomErr),title('eGeom on dataset')

%% Prepare data for optimization
d = addRpt(d,regs);
%% Fit a polinomial of 3rd degree for displacement for angx and angy that will minimize the error on all. Plot the results.


[meanerr,errors,abest,dFixed] = optimize1Dpol(d,regs,0);
frame = hw.getFrame(30);
figure,imagesc(frame.i)
frame = addRpt(frame,regs);
frame.squareSz = 50;
[meanerr,~,abest1im,~] = optimize1Dpol(frame,regs,1);

[~,errors1im,~,dFixed] = optimize1Dpol(d,regs,0,abest1im);
figure, 
plot(results.extraImagesGeomErr,'r')
hold on
plot(errors,'g')
hold on
plot(errors1im,'b')
% Plot the locations in the image plane before and after dix
figure
for n = 1:numel(d)
   [x,y] = Calibration.aux.ang2xySF(d(n).rpt(:,:,2),d(n).rpt(:,:,3),regs,[],1);
   [xF,yF] = Calibration.aux.ang2xySF(dFixed(n).rpt(:,:,2),dFixed(n).rpt(:,:,3),regs,[],1);
   tabplot;
   plot(x,y,'r*')
   hold on
   plot(xF,yF,'g*')
   hold on
   rectangle('position',[0,0,640,360]);
end



pol3 = @(x,a) x*a(1)+x.^2*a(2)+x.^3*a(3);
optFunc = @(x) (errFunc(darr,regs,x,FE) + par.zenithNormW * zenithNorm(regs,x));
    xbest = fminsearchbnd(@(x) optFunc(x),x0,xL,xH,opt);


%% Fit a polinomial of 3rd degree for displacement for angx and angy on a single image that will minimize the error on all. Plot the results.

