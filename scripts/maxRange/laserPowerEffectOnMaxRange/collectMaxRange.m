function [fillRate,zStd,meanZ] = collectMaxRange()
hw = HWinterface;
hw.startStream;
runParams.outputFolder = 'C:\source\algo_ivcam2\scripts\maxRange\laserPowerEffectOnMaxRange\83';
setBitShift(hw);
for laserRatio = fliplr(16:32)
    
    setLaserRatio(hw,laserRatio);
    pause(0.01);
    fr = hw.getFrame();
    ff = Calibration.aux.invisibleFigure; 
    fr.z = double(fr.z);
    fr.z(fr.z==0) = nan;
%     subplot(211);
    imagescNAN(rot90(fr.z/4,2)); colorbar;
    colormap('autumn')
%     subplot(212);
%     fr.z(fr.z/4>500) = 0;
%     imagescNAN(rot90(fr.z/4),[1,1500]); colorbar;
    title(sprintf('Gain = %d / 32 ',laserRatio));
    Calibration.aux.saveFigureAsImage(ff,runParams,'Wall9_7m',sprintf('Z_Image_Level_%d_32',laserRatio))
%     [fillRate(laserRatio),zStd(laserRatio),meanZ(laserRatio)]=showMaxRangeStream(hw);
end
end
function setBitShift(hw)
    hw.cmd('mwd a00501a4 a00501a8 00000005	//Shift by 5 (div by 32)');
end
function setLaserRatio(hw,laserRatio)
    stopIncVal = 'fffffff0 0000000f';
    incVal = '00000012 00000000';
    nInc = laserRatio;
    startAddr = '850a1200';
    for i = 1:nInc
        addr0 = dec2hex(hex2dec(startAddr)+8*(i-1));
        addr1 = dec2hex(hex2dec(addr0)+8);
        if i == nInc
            incCmd = ['mwd ',addr0,' ',addr1,' ',stopIncVal];
        else
            incCmd = ['mwd ',addr0,' ',addr1,' ',incVal];
        end
        hw.cmd(incCmd);
    end
    projShadowUpdate(hw);
    
    
end
function projShadowUpdate(hw)
    hw.cmd('mwd a00d01ec a00d01f0 1 ');
end