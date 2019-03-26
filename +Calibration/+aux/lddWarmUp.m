function lddWarmUp(hw,app,calibParams,runParams,fprintff)
% Create StartButton

if runParams.warm_up
    app.skipWarmUpButton.Visible = 'on';
    app.skipWarmUpButton.Enable='on';
    lastLddTmptr = hw.getLddTemperature();

    fprintff('[-] Ldd warm up...\n');

    fprintff('Ldd temperatures: %2.2f',lastLddTmptr);

    tic;
    lastCurrTime = 0;
    while 1 % Pressing skip will stop this process
        pause(0.1); % When there is no pause, pressing skip doesn't get a chance to happen
        if Calibration.aux.globalSkip(0)
            fprintff(' skipped...\n');
            break; 
        end
        currTime = toc;
    %     % Update waitbar and message
    %     waitbar(currTime/totalTime,f,sprintf('Elapsed Time: %.2f/%.2f',(currTime)/60,totalTime/60));
    %     
    %     % Calculate next estimate 
    %     currTime = toc;
        if (currTime-lastCurrTime>60) || runParams.replayMode
            lastCurrTime = currTime;
            [lddTmptr,~,~ ,~ ] = hw.getLddTemperature();
            fprintff(',%2.2f',lddTmptr);
            if abs(lddTmptr - lastLddTmptr) <  calibParams.warmUp.lddWarmUpTh
                fprintff(' Temperature converged (diff<%.2fdeg)\n',calibParams.warmUp.lddWarmUpTh);
                break; 
            end

            lastLddTmptr = lddTmptr;
        end
    end
    app.skipWarmUpButton.Visible = 'off';
    app.skipWarmUpButton.Enable='off';
    Calibration.aux.globalSkip(1,0);
end
end