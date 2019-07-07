function [] = setGradToNewConfig(hw)
hw.cmd('mwd a00e15f4 a00e15f8 00000130 // JFILgrad1thrAveDiag');
hw.cmd('mwd a00e15f8 a00e15fc 0000FFFA // JFILgrad1thrAveDx');
hw.cmd('mwd a00e15fc a00e1600 0000FFFA // JFILgrad1thrAveDy');
hw.cmd('mwd a00e1600 a00e1604 0000FFFA // JFILgrad1thrMaxDiag');
hw.cmd('mwd a00e1604 a00e1608 000000FF // JFILgrad1thrMaxDx');
hw.cmd('mwd a00e1608 a00e160c 000000FF // JFILgrad1thrMaxDy');
hw.cmd('mwd a00e160c a00e1610 0000FFFA // JFILgrad1thrMinDiag');
hw.cmd('mwd a00e1610 a00e1614 0000FFFA // JFILgrad1thrMinDx');
hw.cmd('mwd a00e1614 a00e1618 0000FFFA // JFILgrad1thrMinDy');
hw.cmd('mwd a00e161c a00e1620 000000FF // JFILgrad1thrSpike');
hw.cmd('mwd a00e15f0 a00e15f4 00000000 // JFILgrad1bypass');
hw.cmd('mwd a00e166c a00e1670 00000001 // JFILgrad2bypass');
hw.shadowUpdate();
end

