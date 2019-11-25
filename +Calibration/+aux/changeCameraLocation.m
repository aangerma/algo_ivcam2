function changeCameraLocation(targetType,dist,ang,calibParams,varargin)
    if calibParams.robot.enable 
        %targetType ,dist in cm ,ang in degrees 
        command = ['plink.exe robot@ev3dev -pw maker -noagent algo_ev3/move_by_target.py -t ' targetType ' -d ' num2str(dist) 'cm -a ' num2str(ang)];
        [status,result] = system(command);
        pause(20);
        if contains(result,'Host does not exist')
            [status,result] = system(command);
            pause(20);
        end
        if status ~= 0
            warning([datestr(now, 0) ' ' result]);
            error([datestr(now, 0) ' Command to robot not successful:' num2str(status) ' for distance: ' num2str(dist) '\n']);
        end
    else
        Calibration.aux.CBTools.showImageRequestDialog(varargin{:});
    end 
end