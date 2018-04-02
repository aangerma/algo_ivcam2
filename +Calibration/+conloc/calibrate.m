function [regs,ok]=calibrate(hw,verbose)
SLOW_DELAY_INIT_VAL = 29000;
FAST_DELAY_OFFSET=80;
N_ITR=20;
warning('off','vision:calibrate:boardShouldBeAsymmetric');

%% :::::::::::::::::::::::::::::::SET:::::::::::::::::::::::::::::::
calibconfig       =struct('name','RASTbiltBypass'     ,'val',true     );
calibconfig(end+1)=struct('name','JFILbypass'        ,'val',false    );
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
calibconfig(end+1)=struct('name','DESTaltIrEn'        ,'val',false );





%% :::::::::::::::::::::::::::::::GET OLD VALUES:::::::::::::::::::::::::::::::

for i=1:length(calibconfig)
    calibconfig(i).oldval=hw.read([calibconfig(i).name '$']);%exact name
end

%% :::::::::::::::::::::::::::::::SET CALIB VALUES:::::::::::::::::::::::::::::::
for i=1:length(calibconfig)
    hw.setReg([calibconfig(i).name   '$'] ,calibconfig(i).val,true);
end
hw.shadowUpdate();

%%calibration loop

%% :::::::::::::::::::::::::::::::CALIBRATE:::::::::::::::::::::::::::::::

hw.setReg('DESTaltIrEn'    ,false);
delaySlow=SLOW_DELAY_INIT_VAL;


ok=false;
incDir=1;
dold = nan;
for i=1:N_ITR
    Calibration.conloc.setAbsDelay(hw,delaySlow,false);
    [d,im]=calcDelayFix(hw);
    if(isnan(d))%CB was not found, throw delay forward to find a good location
        d = 3000;
    end
    if(verbose)
        figure(sum(mfilename));
        imagesc(im);
        title(sprintf('%d (%d)',delaySlow,d));
        drawnow;
    end
    
    if(d==0)
        ok=true;
        break;
    end
    if(~isnan(dold) && abs(dold)<abs(d))
        incDir=-incDir;
    end
    dold=d;
    delaySlow=delaySlow+d*incDir;
    if(delaySlow<0)
        break;
    end
end
  if(verbose)
      close(sum(mfilename));
      drawnow;
  end

Calibration.conloc.setAbsDelay(hw,delaySlow-FAST_DELAY_OFFSET,false);



%% :::::::::::::::::::::::::::::::SET OLD VALUES:::::::::::::::::::::::::::::::
for i=1:length(calibconfig)
    hw.setReg(calibconfig(i).name    ,calibconfig(i).oldval);
end



  
end



function [im1,im2,d]=getSpeperateScansImgs(hw)
    scanDir1gainAddr = '85080000';
    scanDir2gainAddr = '85080480';
    gainCalibValue  = '000ffff0';
    saveVal(1) =hw.readAddr(scanDir1gainAddr);
    saveVal(2) =hw.readAddr(scanDir2gainAddr);
    hw.writeAddr(scanDir1gainAddr,gainCalibValue,true);
    d(1)=hw.getFrame(30);
    hw.writeAddr(scanDir1gainAddr,saveVal(1),true);
    hw.writeAddr(scanDir2gainAddr,gainCalibValue,true);
    d(2)=hw.getFrame(30);
    hw.writeAddr(scanDir2gainAddr,saveVal(2),true);
    
    im1=getFilteredImage(d(1));
    im2=getFilteredImage(d(2));
end
function [d,im]=calcDelayFix(hw)
%im1 - top to bottom
%im2 - bottom to top
[im1,im2]=getSpeperateScansImgs(hw);

%time per pixel in spherical coordinates
nomMirroFreq = 20e3;
t=@(px)acos(-(px/size(im1,1)*2-1))/(2*pi*nomMirroFreq);

p1 = detectCheckerboardPoints(im1);
p2 = detectCheckerboardPoints(im2);
if(isempty(p1) || numel(p1)~=numel(p2))
    d=nan;
else
    d=round(mean(t(p1(:,2))-t(p2(:,2)))/2*1e9);
end

im=cat(3,im1,(im1+im2)/2,im2);

end

function imo=getFilteredImage(d)
im=double(d.i);
im(im==0)=nan;
imv=im(Utils.indx2col(size(im),[5 5]));
imo=reshape(nanmedian_(imv),size(im));
imo=normByMax(imo);
end

