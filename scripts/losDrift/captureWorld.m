function [res] = captureWorld(hw)

%% set regs
%{
hw.setReg('RASTbiltBypass'     ,true);
hw.setReg('RASTbiltSharpnessR'     ,uint8(0));
hw.setReg('RASTbiltSharpnessS'     ,uint8(0));
hw.setReg('JFILbypass$'         ,false);
hw.setReg('JFILbilt1bypass'    ,true);
hw.setReg('JFILbilt2bypass'    ,true);
hw.setReg('JFILbilt3bypass'    ,true);
hw.setReg('JFILbiltIRbypass'   ,true);
hw.setReg('JFILdnnBypass'      ,true);
hw.setReg('JFILedge1bypassMode',uint8(1));
hw.setReg('JFILedge4bypassMode',uint8(1));
hw.setReg('JFILedge3bypassMode',uint8(1));
hw.setReg('JFILgeomBypass'     ,true);
hw.setReg('JFILgrad1bypass'    ,true);
hw.setReg('JFILgrad2bypass'    ,true);
hw.setReg('JFILirShadingBypass',true);
hw.setReg('JFILinnBypass'      ,true);
hw.setReg('JFILsort1bypassMode',uint8(1));
hw.setReg('JFILsort2bypassMode',uint8(1));
hw.setReg('JFILsort3bypassMode',uint8(1));
hw.setReg('JFILupscalexyBypass',true);
hw.setReg('JFILgammaBypass'    ,false);
hw.setReg('JFILgammaBypass'    ,false);
hw.setReg('JFILinvBypass',true);
hw.shadowUpdate();
%}

%% read regs
regs.EXTL.dsmXscale=typecast(hw.read('EXTLdsmXscale'),'single');
regs.EXTL.dsmYscale=typecast(hw.read('EXTLdsmYscale'),'single');
regs.EXTL.dsmXoffset=typecast(hw.read('EXTLdsmXoffset'),'single');
regs.EXTL.dsmYoffset=typecast(hw.read('EXTLdsmYoffset'),'single');

regs.GNRL.zMaxSubMMExp = double(hw.read('GNRLzMaxSubMMExp'));
regs.FRMW.kRaw = hw.read('CBUFspare')';
regs.DEST.depthAsRange = logical(hw.read('depthAsRange'));
regs.DIGG.sphericalOffset = typecast(hw.read('sphericalOffset'), 'int16');
regs.DIGG.sphericalScale = typecast(hw.read('sphericalScale'), 'int16');

regs.DIGG.spare = typecast(hw.read('DIGGspare'),'single');
regs.FRMW.xfov(1) = regs.DIGG.spare(2);
regs.FRMW.yfov(1) = regs.DIGG.spare(3);
regs.FRMW.laserangleH = regs.DIGG.spare(4);
regs.FRMW.laserangleV = regs.DIGG.spare(5);

hw.setReg('DIGGsphericalEn',false);
hw.shadowUpdate();

frame30 = hw.getFrame(30); figure; imagesc(frame30.i)
[points, gridSize] = Validation.aux.findCheckerboard(frame30.i);
hold on; plot(points(:,1),points(:,2),'+r');
camera.zMaxSubMM = 2^regs.GNRL.zMaxSubMMExp;
camera.K = reshape([typecast(regs.FRMW.kRaw,'single')';1],3,3)';

params = Validation.aux.defaultMetricsParams();
params.camera = camera;
params.target.squareSize = 20;
[score, results] = Validation.metrics.gridInterDist(frame30, params);
title(sprintf('InterDist score: %.2f', score));

%v = Validation.aux.pointsToVertices(points, frame30.z, camera);
%[wAngX,wAngY] = vertices2worldAngles(v, regs);
%figure; plot(wAngX,wAngY, '.-'); title('world angles from the checkeckboard');

tempLdd = hw.getLddTemperature;

fileName = sprintf('checkWorld_%4.1fdeg_%s.mat', tempLdd, datetime);
fileName = strrep(fileName, ':','');
fileName = strrep(fileName, ' ','_');
save(fileName, 'frame30', 'regs', 'camera', 'tempLdd');

res.scoreInterDist = score;
res.frame = frame30;
res.camera = camera;
res.regs = regs;
res.tempLdd = tempLdd;

end
