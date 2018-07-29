hw.cmd('iwb e2 03 01 13');% internal modulation (from register) ImodOperation
hw.cmd('iwb e2 08 01 ff');
hw.shadowUpdate();
z_nonsafe=double(hw.getFrame(100).z)/8;
hw.cmd('iwb e2 03 01 93');% extrnal modulation (from MA mod-sign)
hw.shadowUpdate();
z_safe=double(hw.getFrame(100).z)/8;
imagesc(z_nonsafe-z_safe,[-1 2])