function fRes = getMirrorFreq(hw)
% getMirrorFreq - read current resonance frequency of mirror (script contributed by Omer Itzhaki)

res = strsplit(hw.cmd('mrd fffe1100 fffe1104'), '>');
FA_FracPl_SF = hex2single(res{2});

res = strsplit(hw.cmd('mrd fffe10fc fffe1100'), '>');
FA_MirrorDiv = int32(hex2single(res{2}));

hw.cmd('mwd fffe2cf4 fffe2cf8 000000ff'); % RegsTestPortLock - lock FA testpoint
res = strsplit(hw.cmd('mrd fffe2d88 fffe2d8c'), '>');
RegsTpPDClOutB4Red = hex2single(res{2});
hw.cmd('mwd fffe2cf4 fffe2cf8 00000000'); % RegsTestPortLock - unlock FA testpoint

fRes = 960e6 ./ double(FA_MirrorDiv - int32(FA_FracPl_SF * RegsTpPDClOutB4Red)); % formula used by control group to drive the mirror

