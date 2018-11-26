
hw = HWinterface();
hw.startStream();

r=Calibration.RegState(hw);
r.add('rast.*bilt.*bypass'    ,true     );
r.add('invbypass'    ,true     );
r.add('sphericalEn'    ,true     );
r.set();
hw.runScript('MultiFocalCfg.txt');
hw.runScript('MultiFocalROI.txt');

for i = 1:50
%    hw.cmd(cmd{i}); 
   frame(i) = hw.getFrame();
end
z = zeros(50,480,640);
for i = 1:50
   z(i,:,:) = frame(i).z/8;
end
figure, imagesc(squeeze(std(z,[],1)));


r.reset();