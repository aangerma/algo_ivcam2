function [dsmregs] = calibDSM(hw)
%CALIBDSM find DSM scale and offset such that:
% 1. The zero order reported angles are: [angx,angy] =[0,0] 
% 2. The range of angles cover as much as possible.

[angxRawZO,angyRawZO] = zeroOrderAngles(hw);

dsmXscale = hw.read('dsmXscale');
dsmYscale = hw.read('dsmYscale');  
dsmXoffset = hw.read('dsmXoffset'); 
dsmYoffset = hw.read('dsmYoffset'); 
dsm = [dsmXscale,dsmYscale,dsmXoffset,dsmYoffset];

% Turn to spherical, and see the minimal and maximal angles we get per
% axis. 
[angmin,angmax] = minAndMaxAngs(hw);
% Calulcate raw angx/y of the edges: 
angx = [angmin(1);angmax(1)];
angy = [angmin(2);angmax(2)];

angxRaw = invertDSM(angx,dsmXscale,dsmXoffset);
angyRaw = invertDSM(angy,dsmYscale,dsmYoffset);

[dsmregs.EXTL.dsmXscale,dsmregs.EXTL.dsmXoffset] = calcDSMScaleAndOffset(angxRawZO,angxRaw);
[dsmregs.EXTL.dsmYscale,dsmregs.EXTL.dsmYoffset] = calcDSMScaleAndOffset(angyRawZO,angxRaw);

showPrevAndNewImage(hw,dsmregs);

end
function showPrevAndNewImage(hw,dsmregs)
    % Set spherical:
    hw.setReg('DIGGsphericalEn',true);
    % Shadow update:
    hw.shadowUpdate();
    d = hw.getFrame(30);
    subplot(121);
    imagesc(d.i);
    
    % Update DSM
    hw.setReg('EXTLdsmXscale',dsmregs.EXTL.dsmXscale);
    hw.setReg('EXTLdsmYscale',dsmregs.EXTL.dsmYscale);
    hw.setReg('EXTLdsmXoffset',dsmregs.EXTL.dsmXoffset);
    hw.setReg('EXTLdsmYoffset',dsmregs.EXTL.dsmYoffset);
    hw.shadowUpdate();

    d = hw.getFrame(30);
    subplot(122);
    imagesc(d.i);
end
function [scale,offset] = calcDSMScaleAndOffset(ang2zero,angRaw)
% Find the angle in angRaw that should be mapped to 2047. It is the ang
% that is the furthest from the zero order.
[diff,i] = max(abs(angRaw-ang2zero));
angEdge = angRaw(i);
edgeTarget = 2000;
if i == 1
    % Transform angEdge to -2047 and ang2zero to 0.
    offset = single(-angEdge);
    scale = edgeTarget/single(diff);
else
    % Transform angEdge to +2047 and ang2zero to 0.
    offset = single(-ang2zero+diff);
    scale = edgeTarget/single(diff);
end
end
function [angRaw] = invertDSM(ang,scale,offset)
angRaw = (ang+2047)/scale - offset;
end
function [angmin,angmax] = minAndMaxAngs(hw)
% Set spherical:
hw.setReg('DIGGsphericalEn',true);
% Shadow update:
hw.shadowUpdate();
% Get a sample image:
hw.runPresetScript('startStream');
d = hw.getFrame(30);
v = d.i > 0;
axDim = [640,480];
for ax = 1:2
    angmin(ax) = ((find(sum(v,ax),1,'first'))-1-(axDim(ax)-1)/2)/((axDim(ax)-1)/2)*2047;
    angmax(ax) = ((find(sum(v,ax),1,'last' ))-1-(axDim(ax)-1)/2)/((axDim(ax)-1)/2)*2047;
end
% Return to regular coordiantes
hw.setReg('DIGGsphericalEn',false);
% Shadow update:
hw.shadowUpdate();

end

function [angxRaw,angyRaw] = zeroOrderAngles(hw)
% Enable the MC - Enable_MEMS_Driver
hw.cmd('execute_table 140');
% Enable the logger
hw.cmd('mclog 01000000 43 13000 1');


%  Notes: 
%   - Signal is noisy due to ADC noise, multiple reads should be performed together with averaging 
%   - Signal is the PZR voltage before the DSM scale and offset
for i = 1:10
%  Read FA (float, 32 bits)
    [~,FA] = hw.cmd('mrd fffe882C fffe8830');
    angyRaw(i) = typecast(FA,'single');
    % Read SA (float, 32 bits)
    [~,SA] = hw.cmd('mrd fffe880C fffe8810');
    angxRaw(i) = typecast(SA,'single');
end
angxRaw = mean(angxRaw);
angyRaw = mean(angyRaw);
% Disable MC - Disable_MEMS_Driver
hw.cmd('execute_table 147');
end
