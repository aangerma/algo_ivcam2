% This script finds the location of the ZO and the corners of patch where
% it is probably found in case our estimation is noisy.
% This script can work only on units that passed calibration with version
% 1.13 and above. 


dsmMaxAngError = 30; % Maximal error in our estimation of the Mirror angle at rest.
[angx,angy] = meshgrid([-dsmMaxAngError,dsmMaxAngError]); % Mirror values where zero order is possible.

hw = HWinterface(); % Connect to camera

% Verify version of calibration
unitConfigVersion=hw.read('DIGGspare_000');
unitConfigVersion = typecast(unitConfigVersion,'uint8');
unitConfigVersion = unitConfigVersion(1)+100*unitConfigVersion(2);

assert(unitConfigVersion>=113,'A calib version of 1.13 and above is requaired.')
% Read calibration parameters from unit.
currregs.EXTL.dsmXscale=typecast(hw.read('EXTLdsmXscale'),'single');
currregs.EXTL.dsmYscale=typecast(hw.read('EXTLdsmYscale'),'single');
currregs.EXTL.dsmXoffset=typecast(hw.read('EXTLdsmXoffset'),'single');
currregs.EXTL.dsmYoffset=typecast(hw.read('EXTLdsmYoffset'),'single'); 
DIGGspare = hw.read('DIGGspare');
currregs.FRMW.xfov = typecast(DIGGspare(2),'single');
currregs.FRMW.yfov = typecast(DIGGspare(3),'single');
currregs.FRMW.laserangleH = typecast(DIGGspare(4),'single');
currregs.FRMW.laserangleV = typecast(DIGGspare(5),'single');
DIGGspare06 = hw.read('DIGGspare_006');
DIGGspare07 = hw.read('DIGGspare_007');
currregs.FRMW.marginL = int16(DIGGspare06/2^16);
currregs.FRMW.marginR = int16(mod(DIGGspare06,2^16));
currregs.FRMW.marginT = int16(DIGGspare07/2^16);
currregs.FRMW.marginB = int16(mod(DIGGspare07,2^16));
% Load default firmware and update the calibration regs
p = strsplit(cd,filesep); p{end-1} = '+Calibration'; p{end} = 'initScript';
fw = Pipe.loadFirmware(strjoin(p,filesep)); 
fw.setRegs(currregs,'');
regs = fw.get();
% Calculate the location of zero order.
[xPatch,yPatch] = Calibration.aux.ang2xySF(angx,angy,regs,[],1); % Reasonable patch
[xZO,yZO] = Calibration.aux.ang2xySF(0,0,regs,[],1); % Most probable location in the patch (basicaly its center)

% plot the patch in the image plane
figure,
plot(xZO,yZO,'*');
hold on
patch = [xPatch(:),yPatch(:)];
patch(3:4,:) = patch([4,3],:);
patch(end+1,:) = patch(1,:);
plot(patch(:,1),patch(:,2));
axis([0,640,0,480])

% area = polyarea(patch(:,1),patch(:,2)) % Calculate the number of pixels
% in the patch.

