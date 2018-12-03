function [ results  ] = validateDSM( hw,fprintff )
    results = [];
    [angxRawZO,angyRawZO,restFailed] = zeroOrderAngles(hw);
    dsmXscale=typecast(hw.read('EXTLdsmXscale'),'single');
    dsmYscale=typecast(hw.read('EXTLdsmYscale'),'single');
    dsmXoffset=typecast(hw.read('EXTLdsmXoffset'),'single');
    dsmYoffset=typecast(hw.read('EXTLdsmYoffset'),'single');
    
    angx0 = inf;
    angy0 = inf;
    if restFailed
        fprintff('Failed to aquire DSM rest angles.\n');
    else
        angx0 = (angxRawZO+dsmXoffset)*dsmXscale-2047;
        angy0 = (angyRawZO+dsmYoffset)*dsmYscale-2047;
        fprintff('Mirror rest angles in DSM units: [%2.0g,%2.0g].\n',angx0,angy0);
    end
    results.MirrorRestAngX = angx0;
    results.MirrorRestAngY = angy0;
    
    
end
function [angxRaw,angyRaw,restFailed] = zeroOrderAngles(hw)
    % % Enable the MC - Enable_MEMS_Driver
    % hw.cmd('execute_table 140');
    % % Enable the logger
    % hw.cmd('mclog 01000000 43 13000 1');
    
    hw.runPresetScript('stopStream');
    pause(0.1);
    hw.cmd('exec_table 140');% setRestAngle
    pause(0.1);
    % assert(res.IsCompletedOk, 'For DSM calib to work, it should be the first thing that happens after connecting the USB. Before any capturing.' )
    
    
    
    %  Notes:
    %   - Signal is noisy due to ADC noise, multiple reads should be performed together with averaging
    %   - Signal is the PZR voltage before the DSM scale and offset
    hw.cmd('mwd fffe2cf4 fffe2cf8 40');
    hw.cmd('mwd fffe2cf4 fffe2cf8 00');
    for i = 1:100
        hw.cmd('mwd fffe2cf4 fffe2cf8 40');
        %  Read FA (float, 32 bits)
        [~,FA] = hw.cmd('mrd fffe882C fffe8830');
        angyRaw(i) = typecast(FA,'single');
        % Read SA (float, 32 bits)
        [~,SA] = hw.cmd('mrd fffe880C fffe8810');
        angxRaw(i) = typecast(SA,'single');
        hw.cmd('mwd fffe2cf4 fffe2cf8 00');
        
    end
    angxRaw = mean(angxRaw);
    angyRaw = mean(angyRaw);
    
    % % Disable MC - Disable_MEMS_Driver
    hw.runPresetScript('resetRestAngle');
    % hw.runPresetScript('maRestart');
    % hw.runPresetScript('systemConfig');
    pause(0.1);
    hw.cmd('exec_table 140//enable mems drive');
    pause(2);
    hw.cmd('thermloopstart');
    pause(2);
    hw.cmd('exec_table 141//enable mems');
    pause(0.1);
    hw.cmd('exec_table 142//enable FB');
    pause(0.1);
    hw.runPresetScript('startStream');
    pause(0.1);
    %     hw.setSize();
    restFailed = (angxRaw == 0 && angyRaw == 0); % We don't really have the resting angle...
    %     warning('Raw rest angle is zero... This is not likely. Probably setRestAngle script failed.');
    
end
