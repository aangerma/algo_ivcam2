function [im1,im2,d]=getScanDirImagesByLocTable(hw,unFiltered)
% If unfiltered is true, do no perform median filter on results
if ~exist('unfiltered','var')
   unFiltered = 0; 
end

addresses2save  = {'85001400 85001410';...
    '85000000 85000010';...
    'a0050074 a0050078';...
    'a0050090 a0050094';...
    'a005007c a0050080'};

for i = 1:numel(addresses2save)
    cmdStr = sprintf('mrd %s',addresses2save{i});
    values2save{i} = valueStringFromCmd(hw.cmd( cmdStr ));
end

hw.runPresetScript('projectOnlyDownward');
pause(0.1);
d(1)=hw.getFrame(30);

for i = 1:numel(addresses2save)
    cmdStr = sprintf('mwd %s %s',addresses2save{i}, values2save{i});
    hw.cmd( cmdStr );
end
projectorShadowUpdate(hw);

hw.runPresetScript('projectOnlyDownward');
pause(0.1);
d(2)=hw.getFrame(30);
for i = 1:numel(addresses2save)
    cmdStr = sprintf('mwd %s %s',addresses2save{i}, values2save{i});
    hw.cmd( cmdStr );
end
projectorShadowUpdate(hw);

im1=getFilteredImage(d(1),unFiltered);
im2=getFilteredImage(d(2),unFiltered);

end
function valueString = valueStringFromCmd(ansString)
valueString = strsplit(ansString,'=>');
valueString = valueString{2};
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
function projectorShadowUpdate(hw)
hw.cmd('mwd a00d01ec a00d01f0 1  					              // Shadow Update');
end