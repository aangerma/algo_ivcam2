function changeCameraLocation(hw, calibrateRobot, targetType,dist,ang,calibParams, varargin)
    if calibParams.robot.enable 
        if calibrateRobot
            calibrated = false;
            runRobotSafeMoveCommand(targetType, dist, ang)
            params = Validation.aux.defaultMetricsParams;
            params.camera.zMaxSubMM = hw.z2mm();
            params.camera.K = hw.getIntrinsics();
            
            for i =1:8
                frame = hw.getFrame(30);
                angle = Validation.aux.calculateAngle(frame, params, 'distance', dist);
                if abs(angle) <= 0.3
                    calibrated = true;
                    break;
                end
            end
            if ~calibrated
                error('failed calibrating robot to target');
            end
        else    
            runRobotSafeMoveCommand(targetType, dist, ang);
        end
        
    else
        Calibration.aux.CBTools.showImageRequestDialog(varargin{:});
    end 
end

function runRobotSafeMoveCommand(targetType, dist, ang)
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
end

function runRobotUnSafeMoveCommand(forward, dist, rotate)
    %targetType ,dist in cm ,ang in degrees 
    command = ['algo_ev3/move.py -f ' forward ' -d ' num2str(dist), ' -r ' num2str(rotate)];
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
end