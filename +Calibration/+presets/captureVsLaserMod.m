function [LaserPoints,maxMod_dec,frames] = captureVsLaserMod(hw,minModprc,LaserDelta,FramesNum,AverageImBool,output_folder)
% minModprc=percent from max to be minimum value,  LaserDelta=laser loop
% interval (decimal)
frames={}; 
%% read max modulation
s=hw.cmd('irb e2 09 01');
max_hex = sscanf(s,'Address: %*s => %s');
maxMod_dec = hex2dec(max_hex);

starTpoint=round(minModprc*maxMod_dec);
LaserPoints=[starTpoint:LaserDelta:maxMod_dec];
if (LaserPoints(end)~=maxMod_dec)
    LaserPoints(end+1)=maxMod_dec;
end

%%
hw.getFrame(FramesNum,false); 
for i=1:length(LaserPoints)
    val=LaserPoints(i);
    Calibration.aux.RegistersReader.setModRef(hw,val);
    path = fullfile(output_folder,sprintf('ModRef_%03d',val));
    mkdirSafe(path);
    Calibration.aux.SaveFramesWrapper(hw, 'I' , FramesNum , path);
%    frames{i} = hw.getFrame(FramesNum,AverageImBool);
end



end

