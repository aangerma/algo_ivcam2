hw = HWinterface;
hw.cmd('dirtybitbypass')
hw.startStream(0, [480,1024]);
pause(5);
x = [];
cnt = 0;
for iMode = 0:7
    fprintf('--> Switching to mode %d\n', iMode);
    hw.setAlgoLoops(iMode>3, mod(iMode,2)==1, mod(iMode,4)>1);
    for k = 1:10
        fprintf('taking snapshot %d...\n', k);
        cnt = cnt+1;
        x(cnt,:) = [typecast(hw.read('DESTtmptrOffset'),'single'), typecast(hw.read('EXTLdsmXscale'),'single'), typecast(hw.read('EXTLdsmYscale'),'single'), typecast(hw.read('EXTLdsmXoffset'),'single'), typecast(hw.read('EXTLdsmYoffset'),'single'), single(hw.read('EXTLconLocDelaySlow')-uint32(2^31)), single(hw.read('EXTLconLocDelayFastC')), single(hw.read('EXTLconLocDelayFastF'))];
        pause(8);
    end
end

ttl = {'sys-del','Xsc','Xoff','Ysc','Yoff','slow','fastC','fastF'};
figure
for k = 1:8
    subplot(2,4,k)
    hold on
    plot(x(:,k),'-o')
    grid on
    title(ttl{k})
    for kk = 1:7
        plot(ones(1,2)*(10*kk+0.5), minmax(x(:,k)),'k--')
    end
end
