hw = HWinterface;
hw.cmd('dirtybitbyPASS');
hw.startStream;
hw.setReg('DESTbaseline$',single(0));
hw.setReg('DESTbaseline2$',single(0));
hw.setReg('DESTdepthasrange',1);
hw.setReg('JFILinvBypass',1);
hw.setReg('sphericalEn',0);
hw.shadowUpdate;

frame = hw.getFrame(10);
frame = hw.getFrame(10);

hw.setReg('sphericalEn',0);
hw.shadowUpdate;

frameSp = hw.getFrame(10);
frameSp = hw.getFrame(10);

pts = CBTools.findCheckerboardFullMatrix(frame.i,1);
ptsSp = CBTools.findCheckerboardFullMatrix(frameSp.i,1);

rVals = interp2(single(frame.z)/4,vec(pts(:,:,2)),vec(pts(:,:,1)));
rValsSp = interp2(single(frameSp.z)/4,vec(ptsSp(:,:,2)),vec(ptsSp(:,:,1)));

figure,imagesc(reshape(rVals,20,28) - reshape(rValsSp,20,28) )