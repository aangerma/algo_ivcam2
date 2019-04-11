hw = HWinterface;
z2mm = single(hw.z2mm);
hw.cmd('algo_thermloop_en 0');
hw.cmd('dirtybitbypass');
hw.getFrame;
hw.cmd('mwd a0020a6c a0020a70 01000100 // DIGGgammaScale');

hw.setReg('JFILbypass$',1);
hw.setReg('DIGGsphericalEn',1);
hw.cmd('mwd a0020c00 a0020c04 03200c90 // DIGGsphericalScale');
hw.cmd('mwd a0020bfc a0020c00 00fa0500 // DIGGsphericalScale');
hw.setReg('RASTbiltBypass',1);
hw.setReg('DESTbaseline$',single(0));
hw.setReg('DESTbaseline2$',single(0));
hw.setReg('DESTdepthasrange$',1);
hw.setReg('DESTbaseline2$',single(0));

% hw.cmd('mwd a005007c a0050080 ffff0000');  
% hw.cmd('mwd a00d01ec a00d01f0 1 ');
% hw.cmd('mwd fffe482c fffe4830 ffffffff'); 
% Calibration.aux.setLaserProjectionUniformity(hw,1);

hw.shadowUpdate;
%% Change Code Length
txregs.GNRL.codeLength = uint8(64);
hw.setCode(txregs,0);

%%
% cmdstr = [sprintf('iwb e2 04 01 %s',dec2hex(r))];
% cmdstr = [sprintf('iwb e2 04 01 3f')];
% hw.cmd(cmdstr);
% cmdstr = [sprintf('iwb e2 03 01 00')];
% hw.cmd(cmdstr);
% cmdstr = [sprintf('iwb e2 02 01 23')];
% hw.cmd(cmdstr);


clear frames
hw.getFrame(100);
N = 200;
for i = 1:N
   f = hw.getFrame();
%    imagesc(f.i);
%    drawnow
   frames(i) = f;
end

for i = 1:N
    f = frames(i);
    [xg,yg] = meshgrid(1:640,1:360);
    yg(f.i == 0) = 0;
    avgYg = sum(yg)./sum((f.i>0));
%     plot(avgYg);

    raising = diff(avgYg)<0;
    zIm = f.z(:,1:end-1);
    iIm = f.i(:,1:end-1);
    
    raiseIm = zIm;
    raiseIm(:,~raising) = 0;
    fallIm = zIm;
    fallIm(:,raising) = 0;

    frames(i).raiseIm = raiseIm;
    frames(i).fallIm = fallIm;
%     figure,tabplot;
%     imagesc(raiseIm);
%     tabplot;
%     imagesc(fallIm);
%     raiseImI = iIm;
%     raiseImI(:,~raising) = 0;
%     fallImI = iIm;
%     fallImI(:,raising) = 0;
% 
%     frames(i).raiseImI = raiseImI;
%     frames(i).fallImI = fallImI;
end

meanNoZero = @(m) sum(double(m),3)./sum(m~=0,3);
collapseM = @(x) meanNoZero(reshape([frames.(x)],size(frames(1).(x),1),size(frames(1).(x),2),[]));
squareM = @(x) meanNoZero(reshape(double([frames.(x)]),size(frames(1).(x),1),size(frames(1).(x),2),[]).^2); 
meanRaise = (collapseM('raiseIm'));
squareRaise = (squareM('raiseIm'));
stdRaise = sqrt(squareRaise-meanRaise.^2);

meanFall = (collapseM('fallIm'));
squareFall = (squareM('fallIm'));
stdFall = sqrt(squareFall-meanFall.^2);
% meanRaiseI = (collapseM('raiseImI'));
% meanFallI = (collapseM('fallImI'));
% meanI  = (collapseM('i'));
meanZ = (collapseM('z'));
% figure,
% subplot(131); 
% imagesc(meanI);
% subplot(132); 
% imagesc(meanRaiseI);
% subplot(133); 
% imagesc(meanFallI);

% 
% figure,
% tabplot; imagesc(meanRaise/z2mm);colorbar;
% tabplot; imagesc(meanFall/z2mm);colorbar;
% tabplot; imagesc((meanFall-meanRaise)/z2mm,[-30,30]);colorbar;
% 

showVec = 51:290;
figure, 
subplot(121), 
imagesc((meanFall-meanRaise)/z2mm,[-30,30]);colorbar;
title('Diff between avarage up image and average down image (mm)')
subplot(122),
diffIm = (meanFall-meanRaise)/z2mm;
plot(showVec,median(diffIm(showVec,100:540),2)),
title('Median Across Coloumns')
xlabel('row')
ylabel('mm')


figure,
subplot(221);
imagesc((meanFall-meanRaise)/z2mm,[-30,30]);colorbar;
title('Diff between avarage up image and average down image (mm)')
hold on
plot([320,320],[0,360],'r','linewidth',2)
plot([120,120],[0,360],'g','linewidth',2)
plot([420,420],[0,360],'y','linewidth',2)
subplot(222)
plot(showVec,meanFall(showVec,320)/z2mm,'r',showVec,meanRaise(showVec,320)/z2mm,'b')
% errorbar(showVec,meanRaise(showVec,320)/z2mm,stdRaise(showVec,320),'r')
% errorbar(showVec,meanFall(showVec,320)/z2mm,stdFall(showVec,320),'b')

title('Up/Down line section');
subplot(223)
plot(showVec,[meanFall(showVec,120),meanRaise(showVec,120)]/z2mm,'g')
title('Up/Down line section');
subplot(224)
plot(showVec,[meanFall(showVec,420),meanRaise(showVec,420)]/z2mm,'y')
title('Up/Down line section');
drawnow

% ivbin_viewer({uint16([meanFall,zeros(360,1)]),uint16([meanRaise,zeros(360,1)]),uint16(meanZ)})
x = single(flipud(raiseIm));
x = single(flipud(fallIm));
x = x(x>0);
figure,
plot(x/z2mm)
hold on
plot([2373,2373],[0,1000],'r')
plot([2650,2650],[0,1000],'r')
xlabel('pixels')
ylabel('mm')
title('Raising profile single image')