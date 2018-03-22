function [outregs,undistModelLUT,outputErr]=calibrate(d,regs,luts,verbose)
warning('off','vision:calibrate:boardShouldBeAsymmetric');
if(~exist('verbose','var'))
    verbose=true;
end

regs.DIGG.undistBypass=false;
% luts.FRMW.undistModel=Calibration.aux.generateUndistTables([],[],size(d.i));
[udistRegs,udistLuts] = Pipe.DIGG.FRMW.buildLensLUT(regs,luts);
regs=Firmware.mergeRegs(regs,udistRegs);
luts=Firmware.mergeRegs(luts,udistLuts);

stream = Calibration.aux.getInputStream(d,regs,luts);

%% Define optimization settings


x0 = double([regs.FRMW.xfov regs.FRMW.yfov regs.DEST.txFRQpd(1) regs.FRMW.laserangleH regs.FRMW.laserangleV]);

regs = Calibration.DFZ.x2regs(x0,regs);
inputError=Calibration.DFZ.errFunc(stream.s,regs,luts,x0,0);

printErrAndX(x0,inputError,'X0:',verbose)

if(0)
    
    [d0,d1,d2]=ndgrid((-10:1:10)+x0(1),(-10:1:10)+x0(2),(-100:10:100)+x0(3));
    res=zeros(size(d0));
    for i=1:numel(d0)
        res(i)=Calibration.DFZ.errFunc(stream.s,regs,luts,[d0(i) d1(i) d2(i) 0 0],false);

    end

    
end
%%
xbest=x0;
xL = [40 40 0    -3 -3];
xH = [90 90 8000  3  3];
xeps=[.5 .5 0.1 0.1 0.1];
xstep = 1;

[xbest(1:3),outputErr]=gradientDecent2(@(x) Calibration.DFZ.errFunc(stream.s,regs,luts,x,false),x0(1:3),'xStep',[5 5 100],'xeps',xeps(1:3),'plot',verbose,'verbose',verbose);
[xbest(1:3)]=gradientDecent(@(x) Calibration.DFZ.errFunc(stream.s,regs,luts,x,false),x0(1:3),'xL',xL(1:3),'xH',xH(1:3),'plot',false,'verbose',verbose,'eStepTol',0.01,'xeps',0.001);

regs=Firmware.mergeRegs(regs, Calibration.DFZ.x2regs(xbest));
[xbest(4:5),outputErr]=gradientDecent2(@(x) Calibration.DFZ.errFunc(stream.s,regs,luts,x,false),xbest(4:5),'xStep',[.2 .2],'xeps',xeps(4:5),'plot',verbose,'verbose',verbose);
[xbest(4:5),outputErr]=gradientDecent(@(x) Calibration.DFZ.errFunc(stream.s,regs,luts,x,false),x0(4:5),'xL',xL(4:5),'xH',xH(4:5),'plot',false,'verbose',true,'eStepTol',0.0001,'xeps',0.0001);


% if(verbose)
% fprintf('LSR (%5.3f,%5.3f) %5.3f (%+5.3f,%+5.3f) e_dfz=%5.3f[mm] \n',xbest,outputErr);
% end

%%
% quiver3(v(:,:,1),v(:,:,2),v(:,:,3),ve(:,:,1),ve(:,:,2),ve(:,:,3))
% 

printErrAndX(xbest,outputErr,'Xfinal:',verbose)

outregs = Calibration.DFZ.x2regs(xbest);
undistModelLUT = luts.FRMW.undistModel;

end



function printErrAndX(X,e,preSTR,verbose)
if verbose 
    fprintf('%-8s',preSTR);
    fprintf('% 4.2f ',X);
    fprintf('e: %.2f[mm] ',e);
    fprintf('\n');
end
end


