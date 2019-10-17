hw = HWinterface;
hw.cmd('dirtybitbypass')
hw.startStream(0,[480,640]);

hw.setReg('DESTdepthAsRange',1);
hw.setReg('DESTbaseline$',single(0));
hw.setReg('DESTbaseline2',single(0));
hw.cmd('mwd a00e18b8 a00e18bc ffff0000 // JFILinvMinMax');
hw.cmd('mwd a00e1890 a00e1894 00000001 // JFILinvBypass');
hw.cmd('mwd a0020834 a0020838 ffffffff // DCORcoarseMasking_002');    
hw.shadowUpdate;


regs.GNRL.zNorm = hw.z2mm;
regs.FRMW.kWorld = hw.getIntrinsics;
i = 1;

tic;
while i < 20000
    apdVals{i} = hw.cmd('APD_FLYBACK_VALUES_GET');
    frame = hw.getFrame(1,1,1);
    [pts,~] = CBTools.findCheckerboardFullMatrix(frame.i, 0);
    pts = reshape(pts,[],2);
    rIm = single(frame.z)/single(regs.GNRL.zNorm);
    rPts = interp2(rIm,pts(:,1),pts(:,2));
    rtdPts(:,i) = (rPts)*2;
    tim(i) = toc;
    %% Get r,angx,angy
    i = i+1;
    
    if mod(i,100) == 99
        save dbgReduceHist.mat rtdPts apdVals frame tim
    end
    pause(0.1);
end

