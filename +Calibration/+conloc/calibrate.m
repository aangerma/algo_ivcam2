function calibrate(hw)
%% :::::::::::::::::::::::::::::::SET:::::::::::::::::::::::::::::::

calibconfig       =struct('name','RASTbiltBypass'     ,'val',true     );
calibconfig(end+1)=struct('name','JFILbypass'         ,'val',false    );
calibconfig(end+1)=struct('name','JFILbilt1bypass'    ,'val',true     );
calibconfig(end+1)=struct('name','JFILbilt2bypass'    ,'val',true     );
calibconfig(end+1)=struct('name','JFILbilt3bypass'    ,'val',true     );
calibconfig(end+1)=struct('name','JFILbiltIRbypass'   ,'val',true     );
calibconfig(end+1)=struct('name','JFILdnnBypass'      ,'val',true     );
calibconfig(end+1)=struct('name','JFILedge1bypassMode','val',uint8(1) );
calibconfig(end+1)=struct('name','JFILedge4bypassMode','val',uint8(1) );
calibconfig(end+1)=struct('name','JFILedge3bypassMode','val',uint8(1) );
calibconfig(end+1)=struct('name','JFILgeomBypass'     ,'val',true     );
calibconfig(end+1)=struct('name','JFILgrad1bypass'    ,'val',true     );
calibconfig(end+1)=struct('name','JFILgrad2bypass'    ,'val',true     );
calibconfig(end+1)=struct('name','JFILirShadingBypass','val',true     );
calibconfig(end+1)=struct('name','JFILinnBypass'      ,'val',true     );
calibconfig(end+1)=struct('name','JFILsort1bypassMode','val',uint8(1) );
calibconfig(end+1)=struct('name','JFILsort2bypassMode','val',uint8(1) );
calibconfig(end+1)=struct('name','JFILsort3bypassMode','val',uint8(1) );
calibconfig(end+1)=struct('name','JFILupscalexyBypass','val',true     );
calibconfig(end+1)=struct('name','JFILgammaBypass'    ,'val',false    );
calibconfig(end+1)=struct('name','DIGGsphericalEn'    ,'val',true     );
calibconfig(end+1)=struct('name','DIGGnotchBypass'    ,'val',true     );

calibconfig(end+1)=struct('name','DESTaltIrDiv'    ,'val',hw.read('DESTaltIrDiv')/3     );





%% :::::::::::::::::::::::::::::::GET OLD VALUES:::::::::::::::::::::::::::::::

for i=1:length(calibconfig)
    calibconfig(i).oldval=hw.read(calibconfig(i).name);
end

%% :::::::::::::::::::::::::::::::SET CALIB VALUES:::::::::::::::::::::::::::::::
for i=1:length(calibconfig)
    hw.setReg(calibconfig(i).name    ,calibconfig(i).val,true);
end
hw.shadowUpdate();

%%calibration loop

%% :::::::::::::::::::::::::::::::CALIBRATE:::::::::::::::::::::::::::::::
hw.setReg('DESTaltIrEn'    ,true);
e=errFunc(hw);





%% :::::::::::::::::::::::::::::::SET OLD VALUES:::::::::::::::::::::::::::::::
for i=1:length(calibconfig)
    hw.setReg(calibconfig(i).name    ,alibconfig(i).oldval);
end



  
end

function e=errFunc(hw)
scanDir1gainAddr = '85080000';
scanDir2gainAddr = '85080480';
gainCalibValue  = '000ffff0';
saveVal(1) =hw.readAddr(scanDir1gainAddr);
saveVal(2) =hw.readAddr(scanDir2gainAddr);
hw.writeAddr(scanDir1gainAddr,gainCalibValue,true);
d1=hw.getFrame(30);
hw.writeAddr(scanDir1gainAddr,saveVal(1),true);
hw.writeAddr(scanDir2gainAddr,gainCalibValue,true);
d2=hw.getFrame(30);
hw.writeAddr(scanDir2gainAddr,saveVal(2),true);



M=20;
im1=getFilteredImage(d1);

im2=getFilteredImage(d2);

end

function imo=getFilteredImage(d)
im=double(d.i);
im(im==0)=nan;
imv=im(Utils.indx2col(size(im),[5 5]));
imo=reshape(nanmedian_(imv),size(im));
imo=normByMax(imo);
end

