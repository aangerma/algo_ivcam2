state='360p' ;
outPath='X:\Users\hila\XGA\TestingUpDownDelay\F9140336\retest\360p\validPer300\diggScale01680770_sameScaleAsXga\validPer405';
mkdir(outPath);
changeValidPer=0;
ValidPerHex='00000405';
%%
hw = HWinterface;
z2mm = single(hw.z2mm);
hw.cmd('algo_thermloop_en 0');
hw.cmd('dirtybitbypass');
hw.getFrame;
hw.cmd('mwd a0020a6c a0020a70 01000100 // DIGGgammaScale');

if(strcmp(state,'xga') || strcmp(state,'360p'))
    hw.setReg('JFILbypass$',1);
end
hw.setReg('DIGGsphericalEn',1);
if(strcmp(state,'xga'))
    % xga
    hw.cmd('mwd a0020c00 a0020c04 3000770 // DIGGsphericalScale'); %yx 3000400  768x1024
    hw.cmd('mwd a0020bfc a0020c00 1800800 // DIGGsphericalOffset');% 1800800    384x2048
    
end
if (strcmp(state,'xgaUpscale'))
    hw.cmd('mwd a0020c00 a0020c04 1800770 // DIGGsphericalScale');
    hw.cmd('mwd a0020bfc a0020c00 C00800 // DIGGsphericalOffset');
    
end
if (strcmp(state,'xgaUpscale') ||strcmp(state,'xga') )
    showVec = 51:700 ;
    p1=190 ; p2=512; p3=800;
end
if(strcmp(state,'xgaUpscale'))
    %xga upscale
    hw.cmd('mwd a00e0b10 a00e0b14 00000001 // JFILbilt1bypass');
    hw.cmd('mwd a00e0b18 a00e0b1c 00000001 // JFILbilt2bypass');
    hw.cmd('mwd a00e0b20 a00e0b24 00000001 // JFILbilt3bypass');
    hw.cmd('mwd a00e0eb8 a00e0ebc 00000001 // JFILbiltIRbypass');
    hw.cmd('mwd a00e0f04 a00e0f08 00000001 // JFILbypassIr2Conf');
    hw.cmd('mwd a00e1024 a00e1028 00000001 // JFILdnnBypass');
    hw.cmd('mwd a00e1514 a00e1518 00000001 // JFILedge1bypassMode');
    hw.cmd('mwd a00e152c a00e1530 00000001 // JFILedge4bypassMode');
    hw.cmd('mwd a00e1520 a00e1524 00000001 // JFILedge3bypassMode');
    hw.cmd('mwd a00e158c a00e1590 00000001 // JFILgeomBypass');
    hw.cmd('mwd a00e15f0 a00e15f4 00000001 // JFILgrad1bypass');
    hw.cmd('mwd a00e166c a00e1670 00000001 // JFILgrad2bypass');
    hw.cmd('mwd a00e1708 a00e170c 00000001 // JFILinnBypass');
    hw.cmd('mwd a00e1890 a00e1894 00000001 // JFILinvBypass');
    hw.cmd('mwd a00e1b0c a00e1b10 00000001 // JFILmaxPoolBypass');
    hw.cmd('mwd a00e1b24 a00e1b28 00000001 // JFILsort1bypassMode');
    hw.cmd('mwd a00e1b40 a00e1b44 00000001 // JFILsort2bypassMode');
    hw.cmd('mwd a00e1b5c a00e1b60 00000001 // JFILsort3bypassMode');
    showVec = 51:700 ;
end


if(strcmp(state,'360p'))
    % 360p
    hw.cmd('mwd a0020c00 a0020c04 01680770 // DIGGsphericalScale');% yx  def: 1680280  (280h = 640)
    hw.cmd('mwd a0020bfc a0020c00 00b40500 // DIGGsphericalOffset'); % def B40500
    showVec = 40:320 ;
    imH=360;
    p1=120 ; p2=320; p3=420;
end
hw.setReg('RASTbiltBypass',1);
hw.setReg('DESTbaseline$',single(0));
hw.setReg('DESTbaseline2$',single(0));
hw.setReg('DESTdepthasrange$',1);
hw.setReg('DESTbaseline2$',single(0));
if(changeValidPer)
    % changing valid per (xga)
    hw.cmd(['mwd a002010c a0020110 ',ValidPerHex]);
    hw.cmd(['mwd a0020110 a0020114 ',ValidPerHex]);
end
%%
% hw.cmd('mwd a005007c a0050080 ffff0000');
% hw.cmd('mwd a00d01ec a00d01f0 1 ');
% hw.cmd('mwd fffe482c fffe4830 ffffffff');
% Calibration.aux.setLaserProjectionUniformity(hw,1);

hw.shadowUpdate;
%% Change Code Length
% txregs.GNRL.codeLength = uint8(64);
% hw.setCode(txregs,0);

%%
% cmdstr = [sprintf('iwb e2 04 01 %s',dec2hex(r))];
% cmdstr = [sprintf('iwb e2 04 01 3f')];
% hw.cmd(cmdstr);
% cmdstr = [sprintf('iwb e2 03 01 00')];
% hw.cmd(cmdstr);
% cmdstr = [sprintf('iwb e2 02 01 23')];
% hw.cmd(cmdstr);

resH=hw.read('GNRLimgHsize');
resv=hw.read('GNRLimgVsize');
if(~boolean(hw.read('JFILupscalexyBypass')))
    if(boolean(hw.read('JFILupscalex1y0')))
        resH=2*resH;
    else
        resv=2*resv;
    end
    
end

clear frames
hw.getFrame(100);
N = 200;
for i = 1:N
    f = hw.getFrame();
    %    imagesc(f.i);
    %    drawnow
    frames(i) = f;
end
%%
for i = 1:N
    f = frames(i);
    [xg,yg] = meshgrid(1:resH,1:resv);
    yg(f.i == 0) = 0;
    avgYg = sum(yg)./sum((f.i>0));
    %  figure();    plot(avgYg);
    
    raising = diff(avgYg)<0;%figure();    plot(raising);
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

%%


h=figure,
subplot(121),
imagesc((meanFall-meanRaise)/z2mm,[-30,30]);colorbar;
title('Diff between avarage up image and average down image (mm)')
subplot(122),
diffIm = (meanFall-meanRaise)/z2mm;
a=nanmedian(diffIm(showVec,:),2);
NotnanId=~isnan(a);
plot(showVec(NotnanId),a((NotnanId)))
title('Median Across Coloumns')
xlabel('row')
ylabel('mm')
saveas(h,strcat(outPath,'\1'));
%%
h=figure;
subplot(221);
imagesc((meanFall-meanRaise)/z2mm,[-30,30]);colorbar;
title('Diff between avarage up image and average down image (mm)')
hold on
plot([p2,p2],[0,resH],'r','linewidth',2)
plot([p1,p1],[0,resH],'g','linewidth',2)
plot([p3,p3],[0,resH],'y','linewidth',2)
subplot(222); hold all;
scatter(showVec,meanFall(showVec,p2)/z2mm,'r'); scatter(showVec,meanRaise(showVec,p2)/z2mm,'b'); legend('meanFall','meanRaise');
% errorbar(showVec,meanRaise(showVec,320)/z2mm,stdRaise(showVec,320),'r')
% errorbar(showVec,meanFall(showVec,320)/z2mm,stdFall(showVec,320),'b')

title(['Up/Down line section c=',num2str(p2)]);
subplot(223); hold all; 
scatter(showVec,meanFall(showVec,p1)/z2mm,'b'); scatter(showVec,meanRaise(showVec,p1)/z2mm,'g'); legend('meanFall','meanRaise');
title(['Up/Down line section c=',num2str(p1)]);
subplot(224); hold all; 
scatter(showVec,meanFall(showVec,p3)/z2mm, 'b'); scatter(showVec,meanRaise(showVec,p3)/z2mm,'y'); legend('meanFall','meanRaise');
title(['Up/Down line section c=',num2str(p3)]);
drawnow

% ivbin_viewer({uint16([meanFall,zeros(360,1)]),uint16([meanRaise,zeros(360,1)]),uint16(meanZ)})
x = single(flipud(raiseIm));
x = single(flipud(fallIm));
x = x(x>0);


saveas(h,strcat(outPath,'\2'));

figure;
plot(x/z2mm)
hold on
plot([2373,2373],[0,1000],'r')
plot([2650,2650],[0,1000],'r')
xlabel('pixels')
ylabel('mm')
title('Raising profile single image')