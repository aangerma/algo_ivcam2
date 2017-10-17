

% Final Output
figure; imagesc(po.zImg); title('zImg'); impixelinfo;
figure; imagesc(po.iImg); title('iImg'); impixelinfo;
figure; imagesc(po.cImg); title('cImg'); impixelinfo;

% Pre - JFIL
figure; imagesc(po.zImgRAW); title('zImgRAW'); impixelinfo;
figure; imagesc(po.iImgRAW); title('iImgRAW'); impixelinfo;
figure; imagesc(po.cImgRAW); title('cImgRAW'); impixelinfo;

% Pre - DEST
Utils.displayVolumeSliceGUI(po.corr);

% Pre - DCOR
Utils.displayVolumeSliceGUI(po.cma);

%%%%%%
% Some frequent key - regs:
po.regs.DCOR.bypass
po.regs.DEST.bypass
po.regs.JFIL.bypass


% if depth=0, conf=0: 
%       Check JFIL.invBypass or DEST.bypass or dnn (if conf & depth = 1
%       before dnn filter) or JFIL.invMinMax values
% if depth=0, conf~=0: 
%       Check JFIL.bypassIR2conf
% if IR=0: Check DEST.altIRen,

%%%%%
% check why conf always 1 / 0
% check alternative IR mode
% remove blocking regs - such as DCOR/DEST bypass


