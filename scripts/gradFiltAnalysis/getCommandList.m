function [cmdList] = getCommandList(regVal)
cmdList = {['mwd a00e15f4 a00e15f8 0000' regVal ' // JFILgrad1thrAveDiag'];
['mwd a00e15f8 a00e15fc 0000' regVal ' // JFILgrad1thrAveDx'];
['mwd a00e15fc a00e1600 0000' regVal ' // JFILgrad1thrAveDy'];
['mwd a00e1600 a00e1604 0000' regVal ' // JFILgrad1thrMaxDiag'];
['mwd a00e1604 a00e1608 0000' regVal ' // JFILgrad1thrMaxDx'];
['mwd a00e1608 a00e160c 0000' regVal ' // JFILgrad1thrMaxDy'];
['mwd a00e160c a00e1610 0000' regVal ' // JFILgrad1thrMinDiag'];
['mwd a00e1610 a00e1614 0000' regVal ' // JFILgrad1thrMinDx'];
['mwd a00e1614 a00e1618 0000' regVal ' // JFILgrad1thrMinDy'];
['mwd a00e161c a00e1620 0000' regVal ' // JFILgrad1thrSpike']};
end

