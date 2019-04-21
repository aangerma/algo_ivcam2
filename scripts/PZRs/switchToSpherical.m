function [regs] = switchToSpherical(hw)

%sphericalOffset = typecast(hw.read('DIGGsphericalOffset'), 'int16');
%sphericalScale = typecast(hw.read('DIGGsphericalScale'), 'int16');

sphericalScale = int16([640 360]);
sphericalOffset = int16([1280 180]);
newSphericalScale = sphericalScale;
newSphericalOffset = sphericalOffset;
newSphericalScale(1) = int16(round(double(sphericalScale(1))*1.6));
newSphericalScale(2) = int16(round(double(sphericalScale(2))*1.1));
newSphericalOffset(1) = int16(round(double(sphericalOffset(1))+165*4));

%newSphericalScale(1) = int16(round(double(sphericalScale(1))*1.04));
%newSphericalOffset(1) = int16(round(double(newSphericalOffset(1))*1.01));

hw.writeAddr('A0020C00', typecast(newSphericalScale, 'uint32'));
hw.writeAddr('A0020BFC', typecast(newSphericalOffset, 'uint32'));
hw.setReg('DIGGsphericalEn',true);
hw.shadowUpdate();

pause(0.1);

regs.EXTL.dsmXscale=typecast(hw.read('EXTLdsmXscale'),'single');
regs.EXTL.dsmYscale=typecast(hw.read('EXTLdsmYscale'),'single');
regs.EXTL.dsmXoffset=typecast(hw.read('EXTLdsmXoffset'),'single');
regs.EXTL.dsmYoffset=typecast(hw.read('EXTLdsmYoffset'),'single');
regs.DIGG.sphericalOffset = typecast(hw.read('sphericalOffset'), 'int16');
regs.DIGG.sphericalScale = typecast(hw.read('sphericalScale'), 'int16');

end

