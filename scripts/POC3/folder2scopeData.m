function [v,dt]=folder2scopeData(fldr)
f = dirFiles(fldr,'*.trc');
v=cellfun(@(x) io.POC.readLeCroyBinaryWaveform(x),f);
dt = v(1).desc.Ts;
v=[v.y];
end