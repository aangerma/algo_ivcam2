function [calibRegs,calibLuts,score] = runDODCalib(d,regs,luts,verbose)
%RUNDODCALIB calibrates the following properties: 
% Zenith - The offset angles of the mirror. Affects the IR and Depth.
% Undistortion Table - a 32x32 tables that remap an x-y locations. Affects the IR and Depth.
% FOV - This value is used to interperate the angles received from the mirror.Used to convert the xy of each pixel to a true
% angle. (affects the Depth).
% System Delay - an offset to the round trip distance per pixel. rtd = rtd
% - systemDelay. Affects the Depth.

% In this method, we look for an optimal configuration of the regs and luts
% relevant to the above parameters.
% The optimization procedure utilized fminsearch. Which receives an
% input vector to optimize and an objective. The vector consists of the
% relevant registers, the objective is to find a configuration which yields
% a depth image which is best described by a true checkboard (30mm square
% edge) after a rotation and translation in space.

% The calibration iteratively optimize the Zenith,FOV and System delay.
% After convergence, it calculates the distortion map to fix any residual
% errors.
warning('off','vision:calibrate:boardShouldBeAsymmetric') % Supress checkerboard warning
fprintff = @(varargin) verbose&&fprintf(varargin{:});
iter = 2;
dProg = cell(1,iter+1);
dProg{1} = d;
regsProg = cell(1,iter+1);
lutsProg = cell(1,iter+1);
regsProg{1} = regs;
lutsProg{1} = luts;
eProg = zeros(3,iter);
for i = 1:iter
    fprintff('#%d Optimizing Delay, FOV and zenith... \n',i);
    [outregs,eProg(1,i),eProg(2,i),dProg{i+1}]=Calibration.aux.calibDFZ(dProg{i},regsProg{i},verbose);
    regsProg{i+1} = Firmware.mergeRegs(regsProg{i},outregs);
    
    fprintff('#%d Optimizing undistort map... ',i);
    [udistLUTinc,eProg(3,i),undistF]=Calibration.aux.undistFromImg(dProg{i+1}.i,0);
    luts.FRMW.undistModel = typecast(typecast(luts.FRMW.undistModel,'single')+typecast(udistLUTinc,'single'),'uint32');
    lutsProg{i+1} = luts;
    fprintff('done\n');

    dProg{i+1}.z=undistF(dProg{i+1}.z);
    dProg{i+1}.i=undistF(dProg{i+1}.i);
    dProg{i+1}.c=undistF(dProg{i+1}.c);
end
[score,bestI] = min(eProg(1,:));
calibRegs = regsProg{bestI+1};
calibLuts = lutsProg{bestI+1};

if verbose
    fprintf('Geometric Error per iter:         ')
    fprintf('%5.2f ',eProg(1,:)),fprintf('\n')
    fprintf('Geometric Fitting Error per iter: ')
    fprintf('%5.2f ',eProg(2,:)),fprintf('\n')
    fprintf('Distortion Error per iter:        ')
    fprintf('%5.2f ',eProg(3,:)),fprintf('\n')
end
