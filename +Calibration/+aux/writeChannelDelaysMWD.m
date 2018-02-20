function [] = writeChannelDelaysMWD(filename, delayFast, delaySlow, shortFirmwareFormat)
            
if ~exist('shortFirmwareFormat','var')
    shortFirmwareFormat = false;
end

%{
//---------FAST-------------
mwd a0050548 a005054c 00007110 //[m_regmodel.proj_proj.RegsProjConLocDelay]                      (moves loc+metadata to Hfsync 8inc)
mwd a0050458 a005045c 00000004 //[m_regmodel.proj_proj.RegsProjConLocDelayHfclkRes] TYPE_REG     (moves loc+metadata to Hfsync [0-7])
//--------SLOW-------------
mwd a0060008 a006000c 80000020  //[m_regmodel.ansync_ansync_rt.RegsAnsyncAsLateLatencyFixEn] TYPE_REG
%}

if (shortFirmwareFormat)
    fastDelayCmdMul8 = 'mwd a0050548 %08x // RegsProjConLocDelay\n';
    fastDelayCmdSub8 = 'mwd a0050458 %08x // RegsProjConLocDelayHfclkRes\n';
    slowDelayCmd = 'mwd a0060008 8%07x // RegsAnsyncAsLateLatencyFixEn\n';
else
    fastDelayCmdMul8 = 'mwd a0050548 a005054c %08x // RegsProjConLocDelay\n';
    fastDelayCmdSub8 = 'mwd a0050458 a005045c %08x // RegsProjConLocDelayHfclkRes\n';
    slowDelayCmd = 'mwd a0060008 a006000c 8%07x // RegsAnsyncAsLateLatencyFixEn\n';
end

[fileID, err] = fopen(filename, 'wt');
if ~isempty(err)
    error([filename ': ' err]);
end

%fprintf(fileID, '//---------FAST-------------\n');
mod8 = mod(delayFast, 8);
fprintf(fileID, fastDelayCmdMul8, delayFast - mod8);
fprintf(fileID, fastDelayCmdSub8, mod8);
%fprintf(fileID, '//---------SLOW-------------\n');
fprintf(fileID, slowDelayCmd, delaySlow);

fclose(fileID);


end

