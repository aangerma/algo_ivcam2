function [changedRegs] = adjustPCKRspareRegs(hw, newRegVal)
% newRegVal=single([1,1.5,1,1.5,1,1.5]);

%% read pckr spare
[r]=  readPckrSpare(hw);

if ~any(r)
    % set pckr spare
    setPckrSpare(hw, newRegVal);
    hw.cmd('mwd a00d01f4 a00d01f8 00000fff // EXTLauxShadowUpdate');
    pause(1);
end

changedRegs=readPckrSpare(hw);
end

function [r]=  readPckrSpare(hw)
startAddress='a00e1bd8';
for i=1:6
    endaddress=dec2hex(hex2dec( startAddress)+4);
    s=hw.cmd(['mrd ',startAddress,' ',endaddress]);
    s2=strsplit(s,'=> ');  s2=s2{2};
    r(i)=hex2single(s2);
    startAddress=endaddress;
end

end

function []=  setPckrSpare(hw, v)
startAddress='a00e1bd8';
for i=1:length(v)
    endaddress=dec2hex(hex2dec( startAddress)+4);
    value=single2hex(v(i));
    hw.cmd(['mwd ',startAddress,' ',endaddress ' ' value{1}]);
    startAddress=endaddress;
end

end