f1 = load('C:\temp\unitCalib\F8480012\PC20\validateDFZpreReset.mat');
f2 = load('C:\temp\unitCalib\F8480012\PC20\validateDFZpostReset.mat');
f3 = load('C:\temp\unitCalib\F8480012\PC21\validateDFZpostReset.mat');

zCal = [f1.frames.z;zeros(120,640)];
zVal = [f2.frames.z;zeros(120,640)];
zValCal = [f3.frames.z;zeros(120,640)];


ivbin_viewer({zCal,zVal,zValCal})

