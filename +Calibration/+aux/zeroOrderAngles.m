function [angxRaw,angyRaw,restFailed] = zeroOrderAngles(hw,fprintff,runParams,numOfMeasurments)
    % % Enable the MC - Enable_MEMS_Driver
    % hw.cmd('execute_table 140');
    % % Enable the logger
    % hw.cmd('mclog 01000000 43 13000 1');
    if ~exist('numOfMeasurments','var')
        numOfMeasurments = 101;
    end
    
    angyRawVec = zeros(1,numOfMeasurments);
    angxRawVec = zeros(1,numOfMeasurments);

    hw.stopStream;

    pause(3);
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
        angyRawVec(i) = typecast(FA,'single');
        % Read SA (float, 32 bits)
        [~,SA] = hw.cmd('mrd fffe880C fffe8810');
        angxRawVec(i) = typecast(SA,'single');
        hw.cmd('mwd fffe2cf4 fffe2cf8 00');
        
    end
    
    angxRaw = median(angxRawVec);
    angyRaw = median(angyRawVec);
    if ~isempty(runParams) && isfield(runParams, 'outputFolder')
        ff=Calibration.aux.invisibleFigure();
        plot(angxRawVec,angyRawVec,'r*');

        xlabel('x angle raw');
        ylabel('y angle raw');
        hold on
        plot(angxRaw,angyRaw,'b*')
        title(sprintf('Rest Angle Measurements [%.2g,%.2g]',angxRaw,angyRaw));

        Calibration.aux.saveFigureAsImage(ff,runParams,'DSM','Rest_Angle');
    end
    fprintff('DSM: Rest Angle Measurements [%.2g,%.2g], Std: [%.2g,%.2g]\n ',angxRaw,angyRaw,std(angxRawVec),std(angyRawVec));
    
    
    
    % % Disable MC - Disable_MEMS_Driver
    hw.runPresetScript('resetRestAngle');
    % hw.runPresetScript('maRestart');
    % hw.runPresetScript('systemConfig');
%     hw.cmd('dirtybitbypass');
%     pause(0.1);
%     hw.cmd('exec_table 140//enable mems drive');
%     pause(2);
%     hw.cmd('thermloopstart');
%     pause(2);
%     hw.cmd('exec_table 141//enable mems');
%     pause(0.1);
%     hw.cmd('exec_table 142//enable FB');
%     pause(0.1);
%     hw.runPresetScript('startStream');
%     pause(0.1);
    Calibration.aux.startHwStream(hw,runParams);
    
%     hw.setSize();
    restFailed = (angxRaw == 0 && angyRaw == 0); % We don't really have the resting angle...
    %     warning('Raw rest angle is zero... This is not likely. Probably setRestAngle script failed.');
    
end