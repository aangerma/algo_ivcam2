function [im1,im2,d]=getScanDirImgsByGainTable(hw,unFiltered)
% If unfiltered is true, do no perform median filter on results
if ~exist('unfiltered','var')
   unFiltered = 0; 
end

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
pause(0.1);
d(1)=hw.getFrame(30);
hw.writeAddr(scanDir1gainAddr,saveVal(1),true);
hw.writeAddr(scanDir2gainAddr,gainCalibValue,true);
pause(0.1);
d(2)=hw.getFrame(30);
hw.writeAddr(scanDir2gainAddr,saveVal(2),true);

im1=getFilteredImage(d(1),unFiltered);
im2=getFilteredImage(d(2),unFiltered);

end

function imo=getFilteredImage(d,unFiltered)
im=double(d.i);
if ~unFiltered
    im(im==0)=nan;
    imv=im(Utils.indx2col(size(im),[5 5]));
    imo=reshape(nanmedian_(imv),size(im));
    imo=normByMax(imo);
end
end