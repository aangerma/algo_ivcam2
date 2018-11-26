figure,
for factor = 1:4
    setTxRateMF( hw, factor ,0);
    subplot(2,2,factor);
    pause(1);
    frame = hw.getFrame(30);
    imagesc(frame.z/8);
    title(sprintf('repeat %s',num2str(factor-1)));
end