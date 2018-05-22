function [dsmregs] = calibDSM(hw,verbose)
%CALIBDSM find DSM scale and offset such that:
% 1. The zero order reported angles are: [angx,angy] =[0,0]
% 2. The range of angles cover as much as possible.


% Start by setting  my own DSM values. This make sure none of the angles
% are saturated. 
dsmXscale = 5100;
dsmYscale = 3600;
dsmYoffset = 0.55;
dsmXoffset = 0.35;
hw.setReg('EXTLdsmXscale',dsmXscale);
hw.setReg('EXTLdsmYscale',dsmYscale);
hw.setReg('EXTLdsmXoffset',dsmXoffset);
hw.setReg('EXTLdsmYoffset',dsmYoffset);
hw.shadowUpdate();

[angxRawZO,angyRawZO] = zeroOrderAngles(hw);
% Turn to spherical, and see the minimal and maximal angles we get per
% axis.
angxZO = (angxRawZO+dsmXoffset)*dsmXscale - 2047;
angyZO = (angyRawZO+dsmYoffset)*dsmYscale - 2047;

% Set spherical:
hw.setReg('DIGGsphericalEn',true);
% Shadow update:
hw.shadowUpdate();

if(verbose)
    ff=figure(sum(mfilename));
    d = hw.getFrame(30);
    subplot(121);
    imagesc(d.i>0);
    title('Spherical Validity Before DSM Calib')
    
    colZO = (1 + angxZO/2047)/2*(640-1)+1;
    rowZO = (1 + angyZO/2047)/2*(480-1)+1;
    hold on;
    plot( colZO,rowZO,'-s','MarkerSize',10,...
    'MarkerEdgeColor','red',...
    'MarkerFaceColor',[1 .6 .6]);
    
    txt1 = ['\leftarrow' sprintf(' Zero Order Angles=[%.0f,%.0f]',angxZO,angyZO)];
    text(double(colZO),double(rowZO),txt1)
end




[angmin,angmax] = minAndMaxAngs(hw,angxZO,angyZO);
% Calulcate raw angx/y of the edges:
angx = [angmin(1);angmax(1)];
angy = [angmin(2);angmax(2)];

angxRaw = invertDSM(angx,dsmXscale,dsmXoffset);
angyRaw = invertDSM(angy,dsmYscale,dsmYoffset);

[dsmregs.EXTL.dsmXscale,dsmregs.EXTL.dsmXoffset] = calcDSMScaleAndOffset(angxRawZO,angxRaw,'x');
[dsmregs.EXTL.dsmYscale,dsmregs.EXTL.dsmYoffset] = calcDSMScaleAndOffset(angyRawZO,angyRaw,'y');

% Update DSM
hw.setReg('EXTLdsmXscale',dsmregs.EXTL.dsmXscale);
hw.setReg('EXTLdsmYscale',dsmregs.EXTL.dsmYscale);
hw.setReg('EXTLdsmXoffset',dsmregs.EXTL.dsmXoffset);
hw.setReg('EXTLdsmYoffset',dsmregs.EXTL.dsmYoffset);
hw.shadowUpdate();
if(verbose)
    d = hw.getFrame(30);
    subplot(122);
    imagesc(d.i>0);
    title('Spherical Validity After DSM Calib')
    drawnow;
    pause(1);
    close(ff);
end

% Return to regular coordiantes
hw.setReg('DIGGsphericalEn',false);
% Shadow update:
hw.shadowUpdate();
end


function [scale,offset] = calcDSMScaleAndOffset(ang2zero,angRaw,axis)
% Find the angle in angRaw that should be mapped to 2047. It is the ang
% that is the furthest from the zero order.
[diff,i] = max(abs(angRaw-ang2zero));
angEdge = angRaw(i);
edgeTarget = 2047;
margin = 40;
if i == 1
    if axis == 'x'
        % Transform angEdge to -2047 and ang2zero to 0.
        offset = single(-angEdge);
        scale = single(edgeTarget/single(diff));
    elseif axis == 'y'
        % Transform angEdge to -2047+margin and ang2zero to 0.
        offset = single( (edgeTarget/margin*angEdge-ang2zero)/(1-edgeTarget/margin));
        scale = single((edgeTarget-margin)/(ang2zero-angEdge));
    end
else
    % Transform angEdge to +2047 and ang2zero to 0.
    offset = single(-ang2zero+diff);
    scale = single(edgeTarget/single(diff));
end
end
function [angRaw] = invertDSM(ang,scale,offset)
angRaw = (ang+2047)/scale - offset;
end
function [angmin,angmax] = minAndMaxAngs(hw,angxZO,angyZO)
% Get the column and row of the zero order in spherical:
axDim = [640,480];

colZO = uint16(round((1 + angxZO/2047)/2*(axDim(1)-1)+1));
rowZO = uint16(round((1 + angyZO/2047)/2*(axDim(2)-1)+1));
% Get a sample image:
hw.runPresetScript('startStream');
d = hw.getFrame(30);

% Y min angle shouldn't exceed -2047. Y Max angle can exceed. We wish that the column of the zero
% order won't exceed 2047.
% X angles can exceed. [-fovx,0] and [+fovx,0] are mapped to the edges of
% the image. So, it makes sense to look only at the middle line (line of the ZO) when
% handling x.
for ax = 1:2
    if ax == 1
        vCenter =  d.i(rowZO,:) > 0;
        angmin(ax) = ((find(sum(vCenter,ax),1,'first'))-1-(axDim(ax)-1)/2)/((axDim(ax)-1)/2)*2047;
    else
        vAll =  d.i > 0;
        vCenter =  d.i(:,colZO) > 0;
        angmin(ax) = ((find(sum(vAll,ax),1,'first'))-1-(axDim(ax)-1)/2)/((axDim(ax)-1)/2)*2047;
    end
    angmax(ax) = ((find(sum(vCenter,ax),1,'last' ))-1-(axDim(ax)-1)/2)/((axDim(ax)-1)/2)*2047;
end


end

function [angxRaw,angyRaw] = zeroOrderAngles(hw)
% % Enable the MC - Enable_MEMS_Driver
% hw.cmd('execute_table 140');
% % Enable the logger
% hw.cmd('mclog 01000000 43 13000 1');

hw.runPresetScript('stopStream');
hw.runPresetScript('setRestAngle');
% assert(res.IsCompletedOk, 'For DSM calib to work, it should be the first thing that happens after connecting the USB. Before any capturing.' )


%  Notes:
%   - Signal is noisy due to ADC noise, multiple reads should be performed together with averaging
%   - Signal is the PZR voltage before the DSM scale and offset
for i = 1:100
    %  Read FA (float, 32 bits)
    [~,FA] = hw.cmd('mrd fffe882C fffe8830');
    angyRaw(i) = typecast(FA,'single');
    % Read SA (float, 32 bits)
    [~,SA] = hw.cmd('mrd fffe880C fffe8810');
    angxRaw(i) = typecast(SA,'single');
end
angxRaw = mean(angxRaw);
angyRaw = mean(angyRaw);
if angxRaw == 0 && angyRaw == 0
%     warning('Raw rest angle is zero... This is not likely. Probably setRestAngle script failed.');
end
% % Disable MC - Disable_MEMS_Driver
hw.runPresetScript('resetRestAngle');
% hw.runPresetScript('maRestart');
% hw.runPresetScript('systemConfig');

hw.cmd('exec_table 140//enable mems drive');
hw.cmd('exec_table 141//enable mems');
hw.cmd('exec_table 142//enable FB');
hw.runPresetScript('startStream');

end
% 
% function [dsmregs] = calibDSM(hw,verbose)
% %CALIBDSM find DSM scale and offset such that:
% % 1. The zero order reported angles are: [angx,angy] =[0,0]
% % 2. The range of angles cover as much as possible.
% if(verbose)
%     ff=figure(sum(mfilename));
%     d = hw.getFrame(30);
%     subplot(121);
%     imagesc(d.i);
% end
% [angxRawZO,angyRawZO] = zeroOrderAngles(hw);
% 
% dsmXscale = typecast(hw.read('dsmXscale'),'single');
% dsmYscale = typecast(hw.read('dsmYscale'),'single');
% dsmXoffset = typecast(hw.read('dsmXoffset'),'single');
% dsmYoffset = typecast(hw.read('dsmYoffset'),'single');
% % dsm = [dsmXscale,dsmYscale,dsmXoffset,dsmYoffset];
% 
% % Turn to spherical, and see the minimal and maximal angles we get per
% % axis.
% angxZO = (angxRawZO+dsmXoffset)*dsmXscale - 2047;
% angyZO = (angyRawZO+dsmYoffset)*dsmYscale - 2047;
% 
% [angmin,angmax] = minAndMaxAngs(hw,angxZO,angyZO);
% % Calulcate raw angx/y of the edges:
% angx = [angmin(1);angmax(1)];
% angy = [angmin(2);angmax(2)];
% 
% angxRaw = invertDSM(angx,dsmXscale,dsmXoffset);
% angyRaw = invertDSM(angy,dsmYscale,dsmYoffset);
% 
% [dsmregs.EXTL.dsmXscale,dsmregs.EXTL.dsmXoffset] = calcDSMScaleAndOffset(angxRawZO,angxRaw,'x');
% [dsmregs.EXTL.dsmYscale,dsmregs.EXTL.dsmYoffset] = calcDSMScaleAndOffset(angyRawZO,angyRaw,'y');
% 
% % Update DSM
% hw.setReg('EXTLdsmXscale',dsmregs.EXTL.dsmXscale);
% hw.setReg('EXTLdsmYscale',dsmregs.EXTL.dsmYscale);
% hw.setReg('EXTLdsmXoffset',dsmregs.EXTL.dsmXoffset);
% hw.setReg('EXTLdsmYoffset',dsmregs.EXTL.dsmYoffset);
% hw.shadowUpdate();
% if(verbose)
%     d = hw.getFrame(30);
%     subplot(122);
%     imagesc(d.i);
%     drawnow;
%     pause(1);
%     close(ff);
% end
% end
% 
% 
% function [scale,offset] = calcDSMScaleAndOffset(ang2zero,angRaw,axis)
% % Find the angle in angRaw that should be mapped to 2047. It is the ang
% % that is the furthest from the zero order.
% [diff,i] = max(abs(angRaw-ang2zero));
% angEdge = angRaw(i);
% edgeTarget = 2047;
% margin = 40;
% if i == 1
%     if axis == 'x'
%         % Transform angEdge to -2047 and ang2zero to 0.
%         offset = single(-angEdge);
%         scale = single(edgeTarget/single(diff));
%     elseif axis == 'y'
%         % Transform angEdge to -2047+margin and ang2zero to 0.
%         offset = single( (edgeTarget/margin*angEdge-ang2zero)/(1-edgeTarget/margin));
%         scale = single((edgeTarget-margin)/(ang2zero-angEdge));
%     end
% else
%     % Transform angEdge to +2047 and ang2zero to 0.
%     offset = single(-ang2zero+diff);
%     scale = single(edgeTarget/single(diff));
% end
% end
% function [angRaw] = invertDSM(ang,scale,offset)
% angRaw = (ang+2047)/scale - offset;
% end
% function [angmin,angmax] = minAndMaxAngs(hw,angxZO,angyZO)
% % Get the column and row of the zero order in spherical:
% axDim = [640,480];
% 
% colZO = uint16(round((1 + angxZO/2047)/2*(axDim(1)-1)+1));
% rowZO = uint16(round((1 + angyZO/2047)/2*(axDim(2)-1)+1));
% 
% % Set spherical:
% hw.setReg('DIGGsphericalEn',true);
% % Shadow update:
% hw.shadowUpdate();
% % Get a sample image:
% hw.runPresetScript('startStream');
% d = hw.getFrame(30);
% 
% % Y min angle shouldn't exceed -2047. Y Max angle can exceed. We wish that the column of the zero
% % order won't exceed 2047.
% % X angles can exceed. [-fovx,0] and [+fovx,0] are mapped to the edges of
% % the image. So, it makes sense to look only at the middle line (line of the ZO) when
% % handling x.
% for ax = 1:2
%     if ax == 1
%         vCenter =  d.i(rowZO,:) > 0;
%         angmin(ax) = ((find(sum(vCenter,ax),1,'first'))-1-(axDim(ax)-1)/2)/((axDim(ax)-1)/2)*2047;
%     else
%         vAll =  d.i > 0;
%         vCenter =  d.i(:,colZO) > 0;
%         angmin(ax) = ((find(sum(vAll,ax),1,'first'))-1-(axDim(ax)-1)/2)/((axDim(ax)-1)/2)*2047;
%     end
%     angmax(ax) = ((find(sum(vCenter,ax),1,'last' ))-1-(axDim(ax)-1)/2)/((axDim(ax)-1)/2)*2047;
% end
% % Return to regular coordiantes
% hw.setReg('DIGGsphericalEn',false);
% % Shadow update:
% hw.shadowUpdate();
% 
% end
% 
% function [angxRaw,angyRaw] = zeroOrderAngles(hw)
% % % Enable the MC - Enable_MEMS_Driver
% % hw.cmd('execute_table 140');
% % % Enable the logger
% % hw.cmd('mclog 01000000 43 13000 1');
% 
% res = hw.runPresetScript('stopStream');
% res = hw.runPresetScript('setRestAngle');
% % assert(res.IsCompletedOk, 'For DSM calib to work, it should be the first thing that happens after connecting the USB. Before any capturing.' )
% 
% 
% %  Notes:
% %   - Signal is noisy due to ADC noise, multiple reads should be performed together with averaging
% %   - Signal is the PZR voltage before the DSM scale and offset
% for i = 1:100
%     %  Read FA (float, 32 bits)
%     [~,FA] = hw.cmd('mrd fffe882C fffe8830');
%     angyRaw(i) = typecast(FA,'single');
%     % Read SA (float, 32 bits)
%     [~,SA] = hw.cmd('mrd fffe880C fffe8810');
%     angxRaw(i) = typecast(SA,'single');
% end
% angxRaw = mean(angxRaw);
% angyRaw = mean(angyRaw);
% if angxRaw == 0 && angyRaw == 0
% %     warning('Raw rest angle is zero... This is not likely. Probably setRestAngle script failed.');
% end
% % % Disable MC - Disable_MEMS_Driver
% hw.runPresetScript('resetRestAngle');
% % hw.runPresetScript('maRestart');
% % hw.runPresetScript('systemConfig');
% 
% hw.cmd('exec_table 140//enable mems drive');
% hw.cmd('exec_table 141//enable mems');
% hw.cmd('exec_table 142//enable FB');
% hw.runPresetScript('startStream');
% 
% end
