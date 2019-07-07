function [] = byPassEachJFILregs(hw)
hw.cmd('mwd a00e0b10 a00e0b14 00000001 // JFILbilt1bypass');
hw.cmd('mwd a00e0b18 a00e0b1c 00000001 // JFILbilt2bypass');
hw.cmd('mwd a00e0b20 a00e0b24 00000001 // JFILbilt3bypass');
hw.cmd('mwd a00e0eb8 a00e0ebc 00000001 // JFILbiltIRbypass');
hw.cmd('mwd a00e0f04 a00e0f08 00000001 // JFILbypassIr2Conf');
hw.cmd('mwd a00e1024 a00e1028 00000001 // JFILdnnBypass');
hw.cmd('mwd a00e18c0 a00e18c4 00000001 // JFILirShadingBypass');
hw.cmd('mwd a00e1514 a00e1518 00000001 // JFILedge1bypassMode');
hw.cmd('mwd a00e152c a00e1530 00000001 // JFILedge4bypassMode');
hw.cmd('mwd a00e1520 a00e1524 00000001 // JFILedge3bypassMode');
hw.cmd('mwd a00e158c a00e1590 00000001 // JFILgeomBypass');
hw.cmd('mwd a00e15f0 a00e15f4 00000001 // JFILgrad1bypass');
hw.cmd('mwd a00e166c a00e1670 00000001 // JFILgrad2bypass');
hw.cmd('mwd a00e1708 a00e170c 00000001 // JFILinnBypass');
hw.cmd('mwd a00e1b0c a00e1b10 00000001 // JFILmaxPoolBypass');
hw.cmd('mwd a00e1b24 a00e1b28 00000001 // JFILsort1bypassMode');
hw.cmd('mwd a00e1b40 a00e1b44 00000001 // JFILsort2bypassMode');
hw.cmd('mwd a00e1b5c a00e1b60 00000001 // JFILsort3bypassMode');
hw.cmd('mwd a00e1bb0 a00e1bb4 00000001 // JFILupscalexyBypass');
hw.cmd('mwd a00e1538 a00e153c 00000001 // JFILgammaBypass');
hw.shadowUpdate();
end

