hw = HWinterface();
pause(0.5);
hw.getFrame(10,false);
numFrames = 30;
frames_noBypass = hw.getFrame(numFrames,true);
hw.cmd('mwd a00e1890 a00e1894 00000001 // JFILinvBypass');
pause(0.5);
frames_bypass = hw.getFrame(numFrames,true);
hw.cmd('mwd a00e1890 a00e1894 00000000 // JFILinvBypass');
pause(0.5);

figure; 
subplot(2,1,1);imagesc(double(frames_noBypass.z)./4);impixelinfo; title('No JFIL Bypass');
subplot(2,1,2);imagesc(double(frames_bypass.z)./4);impixelinfo; title('JFIL Bypass');
