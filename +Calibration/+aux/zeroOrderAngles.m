function [angxRaw,angyRaw,restFailed] = zeroOrderAngles(hw,numOfMeasurments)
    % % Enable the MC - Enable_MEMS_Driver
    % hw.cmd('execute_table 140');
    % % Enable the logger
    % hw.cmd('mclog 01000000 43 13000 1');
    if ~exist('numOfMeasurments','var')
        numOfMeasurments = 101;
    end
    
    angyRaw = zeros(1,numOfMeasurments);
    angxRaw = zeros(1,numOfMeasurments);

    
    hw.runPresetScript('stopStream');
    pause(0.5);
    hw.cmd('exec_table 140');% setRestAngle
    pause(0.5);
    % assert(res.IsCompletedOk, 'For DSM calib to work, it should be the first thing that happens after connecting the USB. Before any capturing.' )
    
    

    %  Notes:
    %   - Signal is noisy due to ADC noise, multiple reads should be performed together with averaging
    %   - Signal is the PZR voltage before the DSM scale and offset
    hw.cmd('mwd fffe2cf4 fffe2cf8 40');
    hw.cmd('mwd fffe2cf4 fffe2cf8 00');
    for i = 1:numOfMeasurments
        hw.cmd('mwd fffe2cf4 fffe2cf8 40');
        %  Read FA (float, 32 bits)
        [~,FA] = hw.cmd('mrd fffe882C fffe8830');
        angyRaw(i) = typecast(FA,'single');
        % Read SA (float, 32 bits)
        [~,SA] = hw.cmd('mrd fffe880C fffe8810');
        angxRaw(i) = typecast(SA,'single');
        hw.cmd('mwd fffe2cf4 fffe2cf8 00');
        
    end
    angxRaw = median(angxRaw);
    angyRaw = median(angyRaw);
    
    % % Disable MC - Disable_MEMS_Driver
    hw.runPresetScript('resetRestAngle');
    % hw.runPresetScript('maRestart');
    % hw.runPresetScript('systemConfig');
    hw.cmd('dirtybitbypass');
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