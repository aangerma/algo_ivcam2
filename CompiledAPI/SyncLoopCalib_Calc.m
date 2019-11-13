function delayRegs = SyncLoopCalib_Calc(delayRegs, calibParams, delayCalibResults1, delayCalibResults2)
% description: the function should run after each phase of delays calibration.
% inputs:
%   delayRegs - output of IR & Z delays calibration
%   calibParams - struct with general params concerning calibration process
%   delayCalibResults1 - results of first IR & Z delays calibration
%   delayCalibResults1 - results of second IR & Z delays calibration (if already carried out)
% output:
%   delayRegs - enriched regs struct (with delay slopes)
    
    t0 = tic;
    global g_output_dir g_save_input_flag g_save_output_flag g_fprintff g_LogFn g_countRuntime;

    % auto-completions
    if isempty(g_save_input_flag)
        g_save_input_flag = 0;
    end
    if isempty(g_save_output_flag)
        g_save_output_flag = 0;
    end
    func_name = dbstack;
    func_name = func_name(1).name;
    [output_dir, fprintff, fid] = completeInputsToAPI(g_output_dir, func_name, g_fprintff, g_LogFn);

    % input save
    isFinalStage = exist('delayCalibResults2', 'var') && ~isempty(delayCalibResults2);
    if isFinalStage
        suffix = '_final';
    else
        suffix = '_init';
    end
    if g_save_input_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir, 'mat_files' ,[func_name sprintf('%s_in.mat',suffix)]);
        if isFinalStage
            save(fn, 'delayRegs', 'calibParams', 'delayCalibResults1', 'delayCalibResults2');
        else
            save(fn, 'delayRegs', 'calibParams', 'delayCalibResults1');
        end
    end

    % operation - defining sync loop model
    if ~isFinalStage % initialization stage
        delayIR                             = delayCalibResults1.delayIR;
        delayZ                              = delayCalibResults1.delayZ;
        delayRegs.FRMW.conLocDelaySlowSlope = single(calibParams.dataDelay.slowDelayInitSlope);
        delayRegs.FRMW.conLocDelayFastSlope = single(calibParams.dataDelay.fastDelayInitSlope);
        delayRegs.FRMW.dfzCalTmp            = single(delayCalibResults1.temperature);
    else % finalization stage
        delayIR                             = delayCalibResults2.delayIR;
        delayZ                              = delayCalibResults2.delayZ;
        tempDiff                            = delayCalibResults2.temperature - delayCalibResults1.temperature;
        delayRegs.FRMW.conLocDelaySlowSlope = single((double(delayIR) - double(delayCalibResults1.delayIR))/tempDiff);
        delayRegs.FRMW.conLocDelayFastSlope = single((double(delayZ) - double(delayCalibResults1.delayZ))/tempDiff);
        delayRegs.FRMW.dfzCalTmp            = single(delayCalibResults2.temperature);
    end
    fprintff('Setting sync loop: IRdelay = %d+%.2f(T-%.2f), Zdelay = %d+%.2f(T-%.2f)\n',...
        delayIR, delayRegs.FRMW.conLocDelaySlowSlope, delayRegs.FRMW.dfzCalTmp,...
        delayZ, delayRegs.FRMW.conLocDelayFastSlope, delayRegs.FRMW.dfzCalTmp)
    
    % output save
    if g_save_output_flag && exist(g_output_dir,'dir')~=0 
        fn = fullfile(g_output_dir,  'mat_files' , [func_name sprintf('%s_out.mat',suffix)]);
        save(fn, 'delayRegs');
    end
    
    % finalization
    if g_countRuntime
        t1 = toc(t0);
        fprintff('\n%s run time = %.1f[sec]\n', func_name, t1);
    end
    if (fid>-1)
        fclose(fid);
    end
end
