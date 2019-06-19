function [LaserPoints,maxMod_dec] = captureVsLaserMod(hw,minModprc,laserDelta,framesNum,output_folder)
% minModprc=percent from max to be minimum value,  laserDelta=laser loop
% interval (decimal)
%% read max modulation
s=hw.cmd('irb e2 09 01');
max_hex = sscanf(s,'Address: %*s => %s');
maxMod_dec = hex2dec(max_hex);

startPoint=round(minModprc*maxMod_dec);
LaserPoints=[startPoint:laserDelta:maxMod_dec];
if (LaserPoints(end)~=maxMod_dec)
    LaserPoints(end+1)=maxMod_dec;
end

%%
hw.getFrame(framesNum,false); 
for i=1:length(LaserPoints)
    val=LaserPoints(i);
    Calibration.aux.RegistersReader.setModRef(hw,val);
    path = fullfile(output_folder,sprintf('ModRef_%03d',val));
    mkdirSafe(path);
    Calibration.aux.SaveFramesWrapper(hw, 'ZI' , framesNum , path);
%    frames{i} = hw.getFrame(framesNum,AverageImBool);
end



end

