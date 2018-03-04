function [outregs,undistModel,geomErr,resDODParams] = runDODCalib(hw,verbose)
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
resDODParams.initFW = hw.getFirmware();
[regs, luts] = resDODParams.initFW.get();

d = Calibration.aux.readAvgFrame(hw,30);

gaurdBands = [0.0125 0.13];
gaurdBands = [0.00 0.05];



warning('off','vision:calibrate:boardShouldBeAsymmetric') % Supress checkerboard warning
fprintff = @(varargin) verbose&&fprintf(varargin{:});
iter = 1;
dProg = cell(1,iter+1);
dProg{1} = d;
regsProg = cell(1,iter+1);
lutsProg = cell(1,iter+1);
regsProg{1} = regs;
lutsProg{1} = luts;
eProg = zeros(5,iter);
for i = 1:iter
    fprintff('#%d Optimizing Delay, FOV and zenith... \n',i);
    [dfzregs,eProg(1,i),eProg(2,i),dProg{i+1}]=Calibration.aux.calibDFZ(dProg{i},regsProg{i},verbose,gaurdBands);
    regsProg{i+1} = Firmware.mergeRegs(regsProg{i},dfzregs);
    
    
    
    fprintff('#%d Optimizing undistort map... ',i);
    [udistLUTinc,eProg(3,i),undistF]=Calibration.aux.undistFromImg(dProg{i+1}.i,0);
    luts.FRMW.undistModel = typecast(typecast(luts.FRMW.undistModel,'single')+typecast(udistLUTinc','single'),'uint32');
    luts.FRMW.undistModel = 0*luts.FRMW.undistModel;
    lutsProg{i+1} = luts;
    fprintff('done\n');

    dProg{i+1}.z=undistF(dProg{i+1}.z);
    dProg{i+1}.i=undistF(dProg{i+1}.i);
%     dProg{i+1}.c=undistF(dProg{i+1}.c);
    % Eval the erros after distortion
    [~,eProg(4,i),eProg(5,i),~]=Calibration.aux.calibDFZ(dProg{i+1},regsProg{i+1},verbose,gaurdBands,true);
end
[resDODParams.errGeom,bestI] = min(eProg(4,:));
geomErr = resDODParams.errGeom;
resDODParams.errFit = eProg(5,bestI);
resDODParams.errDist = eProg(3,bestI);
resDODParams.eProg = eProg;

warning('off','FIRMWARE:privUpdate:updateAutogen') % Supress checkerboard warning
resDODParams.fw = copy(resDODParams.initFW);
resDODParams.fw.setLut(lutsProg{bestI+1});
undistModel = lutsProg{bestI+1}.FRMW.undistModel;
resDODParams.fw.setRegs(regsProg{bestI+1},'');
resDODParams.fw.get();

% x0 = double([regs.FRMW.xfov regs.FRMW.yfov regs.DEST.txFRQpd(1) regs.FRMW.laserangleH regs.FRMW.laserangleV angXShift]);

outregs.FRMW.xfov = regsProg{bestI+1}.FRMW.xfov;
outregs.FRMW.yfov = regsProg{bestI+1}.FRMW.yfov;
outregs.DEST.txFRQpd = regsProg{bestI+1}.DEST.txFRQpd;
outregs.FRMW.laserangleH = regsProg{bestI+1}.FRMW.laserangleH;
outregs.FRMW.laserangleV = regsProg{bestI+1}.FRMW.laserangleV;
if verbose
    fprintf('Geometric Error per iter:         ')
    fprintf('%5.2f ',eProg(1,:)),fprintf('\n')
    fprintf('Geometric Fitting Error per iter: ')
    fprintf('%5.2f ',eProg(2,:)),fprintf('\n')
    fprintf('Distortion Error per iter:        ')
    fprintf('%5.2f ',eProg(3,:)),fprintf('\n')
end

end
