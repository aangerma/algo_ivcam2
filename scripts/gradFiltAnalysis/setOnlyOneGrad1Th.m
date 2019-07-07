function [] = setOnlyOneGrad1Th(hw, hwCommand)
hw.cmd('mwd a00e15f4 a00e15f8 0000FFFF // JFILgrad1thrAveDiag');
hw.cmd('mwd a00e15f8 a00e15fc 0000FFFF // JFILgrad1thrAveDx');
hw.cmd('mwd a00e15fc a00e1600 0000FFFF // JFILgrad1thrAveDy');
hw.cmd('mwd a00e1600 a00e1604 0000FFFF // JFILgrad1thrMaxDiag');
hw.cmd('mwd a00e1604 a00e1608 0000FFFF // JFILgrad1thrMaxDx');
hw.cmd('mwd a00e1608 a00e160c 0000FFFF // JFILgrad1thrMaxDy');
hw.cmd('mwd a00e160c a00e1610 0000FFFF // JFILgrad1thrMinDiag');
hw.cmd('mwd a00e1610 a00e1614 0000FFFF // JFILgrad1thrMinDx');
hw.cmd('mwd a00e1614 a00e1618 0000FFFF // JFILgrad1thrMinDy');
hw.cmd('mwd a00e161c a00e1620 0000FFFF // JFILgrad1thrSpike');
hw.cmd('mwd a00e15f0 a00e15f4 00000000 // JFILgrad1bypass');
hw.cmd('mwd a00e166c a00e1670 00000001 // JFILgrad2bypass');

hw.cmd(hwCommand);

hw.shadowUpdate();
end

