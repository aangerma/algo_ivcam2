path = 'X:\Users\mkiperwa\gradFilt\figures';
hw = HWinterface();
frame = hw.getFrame(10,false);
pause(0.5);
hw.shutDownLaser;

% setGradToNewConfig(hw);
hwCommand = getCommandList('130');
% {'mwd a00e15f4 a00e15f8 00000130 // JFILgrad1thrAveDiag';'mwd a00e1604 a00e1608 000000130 // JFILgrad1thrMaxDx'; 'mwd a00e1608 a00e160c 000000130 // JFILgrad1thrMaxDy'; 'mwd a00e161c a00e1620 00000130 // JFILgrad1thrSpike'};
%%
for k = 1:length(hwCommand)
    
    byPassEachJFILregs(hw);
    frameNoJfil = hw.getFrame;
    
    setOnlyOneGrad1Th(hw, hwCommand{k});
    
    frame = hw.getFrame(10,false);
    pause(0.5);
    
    frameOnlyGrad = hw.getFrame;
          
    %%
    splitByRegName = strsplit(hwCommand{k},' // ');
    figure;
    subplot(2,1,1); imagesc(frameNoJfil.z./4);impixelinfo; title('Depth - No JFIL');
    subplot(2,1,2); imagesc(frameOnlyGrad.z./4);impixelinfo; title(['Depth - JFIL grad 1 only, with ' splitByRegName{end}]);
    savefig([path '\' splitByRegName{end} '_depth.fig']);
    %%
    figure;
    subplot(2,1,1); h1 = histogram(double(frameNoJfil.z(frameNoJfil.z>0))./4); title('Histogram of Depth - all JFIL is bypassed'); xlabel('[mm]');
    x = h1.BinEdges ;
    y = h1.Values ;
    text(x(1:end-1),y,num2str(y'),'vert','bottom','horiz','center');
    box off
    subplot(2,1,2); h2 = histogram(double(frameOnlyGrad.z(frameOnlyGrad.z>0))./4); title(['Histogram of Depth - all JFIL is bypassed besides JFIL grad 1, with ' splitByRegName{end}]); xlabel('[mm]');
    x = h2.BinEdges ;
    y = h2.Values ;
    text(x(1:end-1),y,num2str(y'),'vert','bottom','horiz','center');
    box off
    savefig([path '\' splitByRegName{end} '_depthHist.fig']);
    %%
    figure;
    subplot(2,1,1); imagesc(frameNoJfil.c);impixelinfo; title('Confidence - No JFIL');
    subplot(2,1,2); imagesc(frameOnlyGrad.c);impixelinfo; title(['Confidence - JFIL grad 1 only, with ' splitByRegName{end}]);
    savefig([path '\' splitByRegName{end} '_conf.fig']);
    %%
    figure;
    subplot(2,1,1); h1 = histogram(frameNoJfil.c(frameNoJfil.c>0), 0.5:15.5); title('Histogram of Confidence - all JFIL is bypassed');
    x = h1.BinEdges ;
    y = h1.Values ;
    text(x(1:end-1),y,num2str(y'),'vert','bottom','horiz','center');
    box off
    subplot(2,1,2); h2 = histogram(frameOnlyGrad.c(frameOnlyGrad.c>0), 0.5:15.5); title(['Histogram of Confidence - all JFIL is bypassed besides JFIL grad 1, with ' splitByRegName{end}]);
    x = h2.BinEdges ;
    y = h2.Values ;
    text(x(1:end-1),y,num2str(y'),'vert','bottom','horiz','center');
    box off
    savefig([path '\' splitByRegName{end} '_confHist.fig']);
end
hw.stopStream;