fw = Pipe.loadFirmware('C:\Temp\talTest\AlgoInternal');
[regs,luts] = fw.get();
hw = HWinterface;
d_fixed = hw.getFrame(30);

hw.runScript('clearUndist.txt');
hw.shadowUpdate;
d_clean = hw.getFrame(30);


tabplot;
imagesc(d_fixed.i);
tabplot;
imagesc(d_clean.i);


%calc angles per pixel
[yg,xg]=ndgrid(0:size(d_fixed.i,1),0:size(d_fixed.i,2));
[angx,angy]=Calibration.aux.xy2angSF(xg,yg,regs,false);
    
    
%find CB points
warning('off','vision:calibrate:boardShouldBeAsymmetric') % Supress checkerboard warning
[p,bsz] = detectCheckerboardPoints(normByMax(d_clean.i)); % p - 3 checkerboard points. bsz - checkerboard dimensions.
[pfixed,~] = detectCheckerboardPoints(normByMax(d_fixed.i)); % p - 3 checkerboard points. bsz - checkerboard dimensions.
it = @(k) interp2(xg,yg,k,reshape(p(:,1)-0.5,bsz-1),reshape(p(:,2)-0.5,bsz-1)); % Used to get depth and ir values at checkerboard locations.
    
%rtd,phi,theta
d_clean.rpt=cat(3,it(angx),it(angy)); % Convert coordinate system to angles instead of xy. Makes it easier to apply zenith optimization.

[xf,yf] = Calibration.aux.ang2xySF(d_clean.rpt(:,:,1),d_clean.rpt(:,:,2),regs,true);
p_clean_fixed = [xf(:),yf(:)];
plot(p(:,1),p(:,2),'r*'); hold on;
plot(pfixed(:,1),pfixed(:,2),'b*'); hold on;
plot(p_clean_fixed(:,1),p_clean_fixed(:,2),'g*'); 


max(sqrt(sum((p - pfixed).^2,2)))
max(sqrt(sum((p_clean_fixed - pfixed).^2,2)))
