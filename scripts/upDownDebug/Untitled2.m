hw = HWinterface;
z2mm = single(hw.z2mm);
% frame = hw.getFrame();
% 
% frame = hw.getFrame(30);
% [dregs,absFast,absSlow] = Calibration.dataDelay.setAbsDelay(hw,[],[]);
absFast = uint32(29118);
absslow = uint32(28968);
[dregs,absFast,absSlow] = Calibration.dataDelay.setAbsDelay(hw,absFast,absslow);
hDelay = hex2dec('00000400');
vDelay = hex2dec('00005B90');
% [dregs,absFast,absSlow] = Calibration.dataDelay.setAbsDelay(hw,[],[]);
hw.cmd('algo_thermloop_en 0');
hw.cmd('dirtybitbypass');
for vD = -120:120:120
%     [dregs] = Calibration.dataDelay.setAbsDelay(hw,absFast+k,absslow);
    hw.runPresetScript('maReset');
%     hw.cmd(sprintf('mwd a0050534 a0050538 %s',dec2hex(hDelay+hD)));
    hw.cmd(sprintf('mwd a0050538 a005053c %s',dec2hex(vDelay+vD)));
    hw.runPresetScript('maRestart');
    hw.shadowUpdate;
    f = hw.getFrame(60);
    col = 320;
    N = 100;
    NB = 100;

    colInd = 28:237;
    colInd = 40:230;
    cols = nan(numel(colInd),N);
    extendedCols = nan(numel(colInd),100);
    sqIm = zeros(size(f.z));
    meanIm = zeros(size(f.z));
    for i = 1:NB
        frame = hw.getFrame();
        meanIm = (meanIm*(i-1) + single(frame.z)/z2mm)/i;
        sqIm = (sqIm*(i-1) + (single(frame.z)/z2mm).^2)/i;
        
        
        zV = single(frame.z(colInd,320))/z2mm;
        cols(:,mod(i-1,N)+1) = zV;
        extendedCols(:,mod(i-1,NB)+1) = zV;
        
    end
    figure(1+vDelay+vD);
    subplot(141);
    plot(cols);
    axis([0,numel(colInd)+1,500,600]);
    subplot(142);
    title(num2str(vDelay+vD))
    plot(std(extendedCols(:,1:i),[],2));
    axis([0,numel(colInd)+1,0,20]);
    subplot(143);
    varim = sqIm-meanIm.^2;
    varim(varim<0) = 0;
    imagesc(sqrt(varim),[0,20]);colorbar;
    drawnow;
    subplot(144);
    imagesc(frame.i,[0,255]);
end