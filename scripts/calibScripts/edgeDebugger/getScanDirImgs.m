function [im1,im2,d]=getScanDirImgs(hw,num2avg)
scanDir1gainAddr = '85080000';
scanDir2gainAddr = '85080480';
gainCalibValue  = '000ffff0';
saveVal(1) =hw.readAddr(scanDir1gainAddr);
saveVal(2) =hw.readAddr(scanDir2gainAddr);
if(any(saveVal'~=hex2dec({'03017','04047'})))
    saveVal;%#ok<VUNUS> %????bad read/write???
end
%     saveVal=uint32(hex2dec({'03017','04047'}));
hw.writeAddr(scanDir1gainAddr,gainCalibValue,true);
d(1)=hw.getFrame(num2avg);
hw.writeAddr(scanDir1gainAddr,saveVal(1),true);
hw.writeAddr(scanDir2gainAddr,gainCalibValue,true);
d(2)=hw.getFrame(num2avg);
hw.writeAddr(scanDir2gainAddr,saveVal(2),true);

im1=getFilteredImage(d(1));
im2=getFilteredImage(d(2));
% im1=normByMax(double(d(1).i));
% im2=normByMax(double(d(2).i));
end

function imo=getFilteredImage(d)
im=double(d.i);
im(im==0)=nan;
imv=im(Utils.indx2col(size(im),[5 5]));
imo=reshape(nanmedian_(imv),size(im));
imo=normByMax(imo);
end