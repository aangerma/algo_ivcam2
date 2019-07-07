function [] = setGradToDefaultConfig(hw)
hw.cmd('mwd a00e15f0 a00e15f4 00000001 // JFILgrad1bypass');
hw.cmd('mwd a00e166c a00e1670 00000000 // JFILgrad2bypass');
hw.shadowUpdate();
end

